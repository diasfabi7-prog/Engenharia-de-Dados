from scripts.inspect_raw import decode_sample, delimiter_from


def test_decode_sample_detects_utf8_bom() -> None:
    text, encoding = decode_sample("\ufeffPeríodo;Produto\n2026/06;Gasolina".encode("utf-8-sig"))

    assert encoding == "utf-8-sig"
    assert "Período" in text


def test_delimiter_from_detects_semicolon_and_comma() -> None:
    assert delimiter_from("UF;Produto;Volume\nRJ;Gasolina;10\n") == ";"
    assert delimiter_from("UF,Produto,Volume\nRJ,Gasolina,10\n") == ","
