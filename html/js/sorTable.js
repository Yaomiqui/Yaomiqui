var sorTablejs = function(setting) {
    "use strict";

    //default
    var config = {
        targetTable: "table.sortable",
        cssAsc: "order-asc",
        cssDesc: "order-desc",
        cssBg: "sortable",
        selectorHeaders: "thead th"
    };
	
    if (setting instanceof String || typeof setting === "string") {
        config.targetTable = setting;
    }else if (typeof setting === "object") {
        Object.keys(setting).forEach(function(key) {
            config[key] = setting[key];
        });
    }
	
    function setEventToAllObject(elem, e, f) {
        [...elem].map((v)=> {
            v.addEventListener(e, f, false);
        });
    }
	
    function getTableElement(elem) {
        var f = th => {
            return th.tagName.toUpperCase() === "TABLE"? th : f(th.parentNode);
        };
        return f(elem.parentNode);
    }
	
    function getTableData(tableElem) {
        var data = [];
        for (var i = 1, l = tableElem.length; i < l; i++) {
            for (var j = 0, m = tableElem[i].cells.length; j < m; j++) {
                if (typeof data[i] === "undefined") {
                    data[i] = {};
                    data[i]["key"] = i;
                }
                data[i][j] = tableElem[i].cells[j].innerText;
            }
        }
        return data;
    }
	
    function sortTableData(tableData, colNo, sortOrder) {
        return tableData.sort((a, b) => {
            if (a[colNo] < b[colNo]) {
                return -1 * sortOrder;
            }            
            if (a[colNo] > b[colNo]) {
                return sortOrder;
            }
            return 0;
        });
    }
	
    function rewriteTableHTML(table, tableData) {
        var html = "";
        tableData.forEach(function(x) {
            html += table.querySelectorAll("tr")[x["key"]].outerHTML;
        });
        table.querySelector("tbody").innerHTML = html;
    }
	
    function removeTHClass(table, tableData) {
        var tableElem = table.querySelectorAll(config.selectorHeaders);
        Object.keys(tableElem).forEach(function(key) {
            tableElem[key].classList.remove(config.cssDesc);
            tableElem[key].classList.remove(config.cssAsc);
        });
    }
	
    function setTHClass(elem, sortOrder) {
        if (sortOrder === 1) {
            elem.classList.add(config.cssAsc);
        }else {
            elem.classList.add(config.cssDesc);
        }
    }
	
    function sortEvent(elem) {
		
        var table = getTableElement(elem);
        if (!table) {
            return;
        }
		
        var tableData = getTableData(table.querySelectorAll("tr"));
		
        var sortOrder = !elem.classList.contains(config.cssAsc) ? 1 : -1;
		
        tableData = sortTableData(tableData, elem.cellIndex, sortOrder);
		
        rewriteTableHTML(table, tableData);
		
        removeTHClass(table, tableData);
        setTHClass(elem, sortOrder);
    }
	
    window.addEventListener("load", function() {
        var elem = document.querySelector(config.targetTable).querySelectorAll(config.selectorHeaders);
        document.querySelector(config.targetTable).classList.add(config.cssBg);
        setEventToAllObject(elem, "click", function(e) {sortEvent(e.target); });
    }, false);

    return this;
};
//Provisional
sorTablejs();
