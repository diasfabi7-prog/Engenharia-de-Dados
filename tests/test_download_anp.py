from scripts.download_anp import fallback_download_url


def test_fallback_adds_download_suffix_to_file_urls() -> None:
    assert (
        fallback_download_url("https://dados.exemplo.gov.br/arquivo.zip")
        == "https://dados.exemplo.gov.br/arquivo.zip/@@download/file"
    )
    assert (
        fallback_download_url("https://dados.exemplo.gov.br/arquivo.csv")
        == "https://dados.exemplo.gov.br/arquivo.csv/@@download/file"
    )


def test_fallback_does_not_duplicate_existing_suffix_or_non_file_url() -> None:
    assert fallback_download_url("https://dados.exemplo.gov.br/arquivo.zip/@@download/file") is None
    assert fallback_download_url("https://dados.exemplo.gov.br/pagina") is None
