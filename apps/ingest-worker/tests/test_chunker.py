from ingest_worker.chunker import chunk_text


def test_chunker_produces_overlapping_chunks():
    text = "abcdefghij" * 200  # 2000 chars
    chunks = list(chunk_text("doc1", text, chunk_size=800, overlap=100))
    assert len(chunks) >= 2
    # First chunk full size, last chunk non-empty.
    assert len(chunks[0].text) == 800
    assert chunks[-1].text != ""


def test_chunker_is_deterministic():
    a = list(chunk_text("doc1", "hello world " * 200))
    b = list(chunk_text("doc1", "hello world " * 200))
    assert [c.id for c in a] == [c.id for c in b]


def test_chunker_handles_empty_input():
    assert list(chunk_text("doc1", "")) == []
    assert list(chunk_text("doc1", "   ")) == []
