module rss.data;
import rss.attributes;
import std.datetime : Clock, DateTime, parseRFC822DateTime;

@XMLName("channel")
struct RSSFeed
{
    //Ovbious
    string title;
    //URL to the channel provider
    string link;
    //description of the channel
    string description;
    //Describes the type of content the channel provides
    string category;
    //The published date
    string pubDate;
    //The time a chanel can be cached before a new request should be sent.
    int    ttl;
    //Optinal image for the feed
    RSSImage image;

    //Items in the feed
    RSSItem[] item;
}

struct RSSImage
{
    //URL to the image
    string url;
    //Description of the Image
    string description;
}

struct RSSItem
{
    //obvious
    string title;
    //URL to item
    string link;
    //Description of the item commonly html
    string description;

	//The published date
    string pubDate;

	DateTime time()
	{
		DateTime dateTime;
		try
		{
			dateTime = cast(DateTime)parseRFC822DateTime(pubDate);
		}
		catch(Exception e) 
		{
			dateTime = cast(DateTime)Clock.currTime;
		}

		//Some items seem to be in the future
		//This could be from errors when creating the feed
		//But future items make no sense in the context
		//of an rss feed reader. 
		if(dateTime > cast(DateTime)Clock.currTime) {
			dateTime = cast(DateTime)Clock.currTime;
		}

		return dateTime;
	}
}
