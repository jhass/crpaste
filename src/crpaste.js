hljs.initHighlightingOnLoad();

function clearSelection() {
  var anchors = document.querySelectorAll(".line-numbers a");
  for (var i = 0; i < anchors.length; ++i) {
    anchors[i].classList.remove("selected");
  }
}

function updateSelectionFromURL() {
  if (window.location.hash[1] == "L") {
    var name = window.location.hash.substring(2),
        anchors = name.split("-"),
        start = parseInt(anchors[0]),
        end = parseInt(anchors[1] || anchors[0]),
        anchor;

    clearSelection();
    for (var number = start; number <= end; ++number) {
      anchor = document.querySelector(".line-numbers a[name='L" + number + "']");
      if (anchor) {
        anchor.classList.add("selected");
      }
    }
  }
}

function select(event) {
  var target = this.name.substring(1);

  event.preventDefault();

  if (event.shiftKey) {
    var anchors = document.querySelectorAll(".line-numbers a.selected"),
        lowest = anchors[0],
        highest = anchors[anchors.length-1],
        from, to;

    if (lowest) {
      lowest = parseInt(lowest.name.substring(1));
    }

    if (highest) {
     highest = parseInt(highest.name.substring(1));
    }

    if (highest > target) {
      to = highest;
    } else {
      to = target;
    }

    if (lowest < target) {
      from = lowest;
      to = target;
    } else {
      from = target;
    }

    target = from + "-" + to;
  }

  window.location.hash = "#L" + target;
  return false;
}

window.addEventListener("load", function() {
  updateSelectionFromURL();
  window.addEventListener("hashchange", updateSelectionFromURL);

  var anchors = document.querySelectorAll(".line-numbers a");
  for (var i = 0; i < anchors.length; ++i) {
    anchors[i].addEventListener("click", select);
  }
});
