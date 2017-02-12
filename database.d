void addFeed(HTTPServerRequest req, HTTPServerResponse resp)
{
    auto user   = validateRequest(req);
    auto feed   = req.extractFeed();
    auto db     = RSS_DBClient(userstring);
    auto storedFeed = db.getFeed(feed);
    if(storedFeed.empty) {
      auto rssFeed = downloadRSSFeed(feed);
      db.insertFeed(rssFeed);
      foreach(item; rssFeed) {
        db.insertItem(rssFeed.domain, item);
      }

      storedFeed = db.getFeed(feed);
      addFeedToPoll(feed);
    }

    db.insertSubs(userID, storedFeed[0].id);
    resp.bodyWriter.serializeJson(storedFeed);
}

void getFeedItems(HTTPServerRequest req, HTTPServerResponse resp)
{
    auto user  = validateRequest(req);
    auto feed  = req.extractFeed();
    auto db    = RSS_DBClient(userstring);

    auto items = db.getItems(user, feed);
    if(items.empty) {
      return; //Basically file not found
    }

    resp.bodyWriter.serializeJson(items);
}
