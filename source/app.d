import vibe.d;
import vibe.data.json;
import vibe.inet.url;
import rss.xml, rss.data;
import database.client;
import std.format;
import std.stdio;
import std.json;
import jwt.jwt;

bool validateToken(HTTPServerRequest req, out string email)
{
	auto token_id = req.headers["Authorization"];
	requestHTTP(format("https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=%s", token_id),
	(scope request) {
		request.method = HTTPMethod.GET;
	},
	(scope response) {
		auto text = response.bodyReader.readAllUTF8();
		auto json = parseJson(text);
		if(json["email_verified"].to!bool)
			email = json["email"].get!string;
		else 
			email = "";
	});

	return email.length > 0;
}

auto trackFeeds()
{
	
}

auto insertFeeds(string[] urls, bool addFeed = true)
{
	auto client = DBClient(userstring);
	foreach(url; urls) 
	{
   		requestHTTP(url,
		(scope request) {
			request.method = HTTPMethod.GET;
		},
		(scope res) {
			auto channel = decodeXML!RSSFeed(res.bodyReader.readAllUTF8());
			if(addFeed) {
				client.addFeed(url, channel);
			} else {
				client.updateFeed(channel);
			}
		});
	}
}

void addSubscription(HTTPServerRequest req, HTTPServerResponse resp)
{
	string email;
	if(!validateToken(req, email))
		return;

	auto client = DBClient(userstring);
	auto user   = client.getUser(email);
	auto url    = req.bodyReader.readAllUTF8();
	insertFeeds([url]);
	auto feed = client.getFeed(url);
	client.addSubscription(user, feed.id);
	
	//Verbose... also allocates a bunch of stuff. 
	Json json = Json.emptyObject;
	json["success"] = true;
	auto jfeed = Json(["id": Json(feed.id), "title": Json(feed.title)]);
	json["feed"] = jfeed;
	resp.writeBody(json.toString());
}

void getSubscriptions(HTTPServerRequest req, HTTPServerResponse resp)
{
	string email;
	if(!validateToken(req, email))
		return;

	auto client = DBClient(userstring);
	auto user   = client.getUser(email);
	resp.writeBody(serializeToJsonString(client.getSubscriptions(user)));
}


void getAllFeeds(HTTPServerRequest req, HTTPServerResponse resp) {
	string email;

	if(!validateToken(req, 	email))
		return;

	auto client = DBClient(userstring);
	auto user = client.getUser(email);
	resp.writeBody(serializeToJsonString(client.getAllUserItems(user)));
}

void getFeed(HTTPServerRequest req, HTTPServerResponse resp)
{
	string email;
	if(!validateToken(req, email))
		return;

	auto client = DBClient(userstring);
	auto user = client.getUser(email);
	auto feed = Path(req.path).relativeTo(Path("/items/")).toString().to!int;
	resp.writeBody(serializeToJsonString(client.getItems(feed)));
}

void login(HTTPServerRequest req, HTTPServerResponse resp)
{
	string email;
	if(validateToken(req, email))
	{
		auto client = DBClient(userstring);
		client.addUser(email);
		resp.writeBody(q{{"valid": true}});
	}
	else 
		resp.writeBody(q{{"valid": false}});
}

void pollFeeds()
{
	auto db = DBClient(userstring);
	auto feeds = db.getAllSources().map!(x => x.source).array;
	insertFeeds(feeds, false);
}

shared static this() {
	DBClient.setup();

	auto router = new URLRouter();
	router.post("/subs/add", &addSubscription);
	router.get("/subs/all", &getSubscriptions);
	router.get("/items/0", &getAllFeeds);
	router.get("/items/*", &getFeed);
	router.get("/login", &login);
	router.get("*", serveStaticFiles("public/"));

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, router);

	setTimer(1.seconds, toDelegate(&pollFeeds), false);
	setTimer(1.hours, toDelegate(&pollFeeds), true);
}
