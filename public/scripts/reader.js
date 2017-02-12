function sendReq(method, url, value, resp)
{
    let req = new XMLHttpRequest();
    req.onreadystatechange  = function() {
      if(req.readyState == XMLHttpRequest.DONE && req.status == 200) {
          resp(req.responseText);
      }
    }

    req.open(method, url);
    req.setRequestHeader("Authorization",
                         sessionStorage.getItem("token"));
    req.send(value);
}

Element.prototype.insertChildAt = function(child, index) {
  if(index >= this.children.length) {
    this.appendChild(child);
  } else {
    this.insertBefore(child, this.children[index]);
  }
};

function toggleItemHTML(div, item) {
  let status = div.className;
  let children = document.getElementById("content_container").children;
  for(let i = 0; i < children.length; i++) {
    children[i].className = "content_item";
  }

  if(status === "content_item") {
    div.className = "content_item_active";
  }
}


function addItem(item) {
  let content = document.getElementById("content_container");
  let div = document.createElement("div");
  div.className = "content_item";

  let itemContent = document.createElement("div");
  itemContent.className = "item_container";
  itemContent.innerHTML = item.content;

  let title = document.createElement("span");
  title.className += "content_title";
  title.innerHTML = item.title;

  div.appendChild(title);
  div.appendChild(itemContent);
  content.appendChild(div);

  div.onclick = () => toggleItemHTML(div, item);
}

function getItems(id) {
  sendReq("GET", "items/" + id, null, (resp) => {
    let items = JSON.parse(resp);
    for(let item of items) {
      addItem(item);
    }
  });
}

function feedClicked(div, feed) {
  div.className = "feed_rss_selected";

  let content = document.getElementById("content_container");
  while (content.hasChildNodes()) {
    content.removeChild(content.lastChild);
  }
  content.activeItem = null;
  getItems(feed.id);
}

function addSubsHtml(feed) {
  let subs = document.getElementById("subs");
  let div   = document.createElement("div");
  div.className += "feed_rss";
  div.onclick = () => feedClicked(div, feed);
  let icon = document.createElement("img");
  icon.src = "images/rss-icon.png";
  icon.className += "feed_icon";
  let title = document.createElement("span");
  title.className += "feed_title";

  let fixedTitle = feed.title.slice(0, 22);
  title.innerHTML = fixedTitle;


  div.appendChild(icon);
  div.appendChild(title);
  subs.appendChild(div);
}

function getSubs()
{
    sendReq("GET", "subs/all", null, (resp) => {
        let obj = JSON.parse(resp);
        let subs = document.getElementById("subs");
        subs.feeds = obj;
        for(let feed of obj) {
            addSubsHtml(feed);
        }
    });
}

function addFeed(feed)
{
    sendReq("POST", "subs/add", feed, (resp) => {
        let obj = JSON.parse(resp);
        if(obj.success) {
            addSubsHtml(obj.feed);
        }
        console.log("We added a feed!");
    });
}

getSubs();

window.onload = (x) => {
    addSubsHtml({title: "all", id:"0"});

    document.getElementById("add_feed_btn").addEventListener("click", () => {
        let feed = prompt("Add a feed!");
        let subs = document.getElementById("subs");
        let present = subs.feeds.find((x) => x.source === feed);
        if(!present)
        {
            addFeed(feed);
        }
    });
};
