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

function hideActiveElement(content) {
  let active = content.getElementsByClassName('content_item_active');
  let elem   = active.length > 0 ? active[0] : null;
  if(elem) {
    elem.className = "content_item";
    let itemNode = elem.getElementsByClassName("item_container")[0];
    itemNode.removeChild(itemNode.lastChild);
  }
}

function toggleItemHTML(content, div) {
  let status = div.className;
  hideActiveElement(content);

  if(status === "content_item") {
    div.className = "content_item_active";
    let itemNode = div.getElementsByClassName("item_container")[0];


    let iframe = document.createElement("iframe");
    itemNode.appendChild(iframe);
    iframe.id = "content_frame";
    iframe.scrolling = "no";
    iframe.contentWindow.document.open();
    iframe.contentWindow.document.write(
      "<body>" +
        "<script src=\"https://code.jquery.com/jquery-3.1.1.min.js\"></script>" +
        itemNode.data +
      "</body>");
    iframe.contentWindow.document.close();
    iframe.height = "0";
    iframe.onload = function() {
      let height = this.contentWindow.document.body.scrollHeight;
      this.style.height = height + "px";
    }

    document.body.scrollTop = div.offsetTop - 100;
  }
}


function addItem(item) {
  let content = document.getElementById("content");
  let div = document.createElement("div");
  div.className = "content_item";

  let titleCont = document.createElement("div");
  titleCont.className = "content_title_container";

  let title = document.createElement("span");
  title.className += "content_title";
  title.innerHTML = item.title;

  let itemCont = document.createElement("div");
  itemCont.className = "item_container";
  itemCont.data = item.content;

  let link = document.createElement("a");
  link.href = item.url;
  link.target = "_blank";
  link.innerHTML = (new Date(item.time).toLocaleString());
  link.className = "item_link";


  titleCont.appendChild(title);
  div.appendChild(titleCont);

  itemCont.appendChild(link);
  div.appendChild(itemCont);
  content.appendChild(div);

  titleCont.onclick = () => toggleItemHTML(content, div);
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

  let content = document.getElementById("content");
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

function addFeed() {
  let input = prompt("Add a feed");
  sendReq("POST", "subs/add", input, (resp) => {
    let obj = JSON.parse(resp);
    let feed = obj.feed;
    addSubsHtml(feed);
  })
}

function addAddButton() {
  let subs = document.getElementById("subs");
  let div   = document.createElement("div");
  div.className += "feed_rss";
  div.onclick = () => addFeed();
  let icon = document.createElement("img");
  icon.src = "images/rss-icon.png";
  icon.className += "feed_icon";
  let title = document.createElement("span");
  title.className += "feed_title";
  title.innerHTML = "add feed";

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

        addAddButton();
    });
}

getSubs();

window.onload = (x) => {
    addSubsHtml({title: "all", id:"0"});
    addSubsHtml({title: "unread", id:"0"});
};
