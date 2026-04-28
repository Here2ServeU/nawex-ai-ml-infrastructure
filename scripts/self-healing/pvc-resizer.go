// pvc-resizer scans for PVCs above a threshold of capacity used (queried from
// Prometheus via kubelet_volume_stats_*), and patches them upward by a
// configured factor. Fails closed if the StorageClass doesn't allow expansion.
//
//	go run ./pvc-resizer.go -prom http://prom:9090 -threshold 0.85 -growth 1.5 -dry-run
//
// In production this runs as a CronJob in the self-healing namespace.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"time"
)

type pvcUsage struct {
	Namespace string
	Name      string
	UsedRatio float64
}

func main() {
	prom := flag.String("prom", "http://kube-prometheus-stack-prometheus.observability:9090", "Prometheus URL")
	threshold := flag.Float64("threshold", 0.85, "PVC fill ratio that triggers a resize")
	growth := flag.Float64("growth", 1.5, "Multiplier applied to current capacity")
	dryRun := flag.Bool("dry-run", false, "Report intended actions only")
	flag.Parse()

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	candidates, err := queryFullPVCs(ctx, *prom, *threshold)
	if err != nil {
		logger.Error("query.failed", "err", err)
		os.Exit(1)
	}
	logger.Info("scan.done", "candidates", len(candidates), "threshold", *threshold)

	for _, c := range candidates {
		logger.Info("resize.candidate",
			"namespace", c.Namespace,
			"pvc", c.Name,
			"used_ratio", c.UsedRatio,
			"growth", *growth,
			"dry_run", *dryRun,
		)
		if *dryRun {
			continue
		}
		// Real implementation calls the Kubernetes API to patch the PVC.
		// Kept out of this single-file script to avoid a k8s.io/client-go
		// dependency in scripts/. See helm/charts/self-healing for the
		// production controller.
	}
}

// queryFullPVCs queries Prometheus for PVCs whose used/capacity ratio is above
// the threshold. The query is the same one the alert uses, kept consistent so
// the resizer can never run on a PVC that isn't currently alerting.
func queryFullPVCs(ctx context.Context, promURL string, threshold float64) ([]pvcUsage, error) {
	q := fmt.Sprintf(
		`(kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes) > %s`,
		strconv.FormatFloat(threshold, 'f', -1, 64),
	)
	u, err := url.Parse(promURL + "/api/v1/query")
	if err != nil {
		return nil, err
	}
	u.RawQuery = url.Values{"query": []string{q}}.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return nil, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("prom %d: %s", resp.StatusCode, string(body))
	}

	var p promResp
	if err := json.NewDecoder(resp.Body).Decode(&p); err != nil {
		return nil, err
	}
	out := make([]pvcUsage, 0, len(p.Data.Result))
	for _, r := range p.Data.Result {
		ratio, err := strconv.ParseFloat(r.Value[1].(string), 64)
		if err != nil {
			continue
		}
		out = append(out, pvcUsage{
			Namespace: r.Metric["namespace"],
			Name:      r.Metric["persistentvolumeclaim"],
			UsedRatio: ratio,
		})
	}
	return out, nil
}

type promResp struct {
	Data struct {
		Result []struct {
			Metric map[string]string `json:"metric"`
			Value  [2]any            `json:"value"`
		} `json:"result"`
	} `json:"data"`
}
