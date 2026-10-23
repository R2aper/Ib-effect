.pragma library

var documents = [
    {
        pattern: /ГОСТ Р ИСО\/МЭК 27005-2010|ГОСТ Р ИСО\/МЭК 27005|ГОСТ 27005/gi,
        url: "https://unicoms.biz/upload/medialibrary/338/3389c91d011a3fa83b4600bcac6c188f.pdf?ysclid=mvkkxlmpkp796121222"
    },
    {
        pattern: /ГОСТ Р 57580\.3-2022|ГОСТ 57580\.3/gi,
        url: "https://regulhub.kaspersky.ru/upload/iblock/9f8/j4uhovgcpfhzbu494dl0j7e2eopk8fdt.pdf?ysclid=mvkkrlomnx590674618"
    },
    {
        pattern: /ГОСТ Р 58771-2019/gi,
        url: "https://files.stroyinf.ru/Data2/1/4293724/4293724640.pdf"
    },
    {
        pattern: /Методика (?:моделирования угроз|оценки угроз) ФСТЭК России от 05\.02\.2021|Методик(?:а|и|е|ами|ам) ФСТЭК(?: России)?(?: от 05\.02\.2021|\s*\(2021\))?|ФСТЭК 05\.02\.2021/gi,
        url: "https://fstec.ru/dokumenty/vse-dokumenty/spetsialnye-normativnye-dokumenty/metodicheskij-dokument-ot-5-fevralya-2021-g"
    },
    {
        pattern: /ГОСТ Р 59339-2021/gi,
        url: "https://www.altirixgroup.com/wp-content/uploads/2022/07/gost-r-59339-2021-zashhita-informaczii-v-proczesse-upravleniya-riskami-dlya-sistemy.pdf"
    }
]

function escapeHtml(text) {
    return String(text)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;")
}

function linkify(text) {
    var result = escapeHtml(text)
    for (var i = 0; i < documents.length; i++) {
        var doc = documents[i]
        result = result.replace(doc.pattern, function (label) {
            return '<a href="' + doc.url.replace(/&/g, "&amp;") + '">' + label + "</a>"
        })
    }
    return result
}

function linkifyMarkdown(text) {
    var result = String(text)
    for (var i = 0; i < documents.length; i++) {
        var doc = documents[i]
        result = result.replace(doc.pattern, function (label) {
            return "[" + label + "](" + doc.url + ")"
        })
    }
    return result
}
