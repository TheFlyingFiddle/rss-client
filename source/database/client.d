module database.client;

import mysql;
import database.definition;
import sql.query;
import sql.database;
import rss.data;

enum userstring = "host=localhost;user=root;pwd=warhammer2;port=8888";
alias DB = RSSDatabase;

alias Con = typeof(MySQLClient.lockConnection());

struct DBClient
{
	Con con;
	this(string userstring)
	{
		auto db = new MySQLClient(userstring);
		this.con = db.lockConnection();
		con.use(getDatabaseName!DB);
	}

	~this()
	{
		this.con.disconnect();
	}

	static void setup()
	{
		auto db = new MySQLClient(userstring);
		auto con = db.lockConnection();
		setupDatabase!DB(con);
	}

	void addUser(string email)
	{
		auto insert = SQLInsertOrUpdate!(DB.Users, "email")();
		insert.email = email;
		insert.insert(con);
	}

	void addFeed(string source, RSSFeed feed)
	{
		auto insert = SQLInsertOrUpdate!(DB.Feeds, "source", "domain", "title", "description", "ttl")();
		insert.title = feed.title;
		insert.description = feed.description;
		insert.source = source;
		insert.domain = feed.link;
		insert.ttl  = 60; //Once every hour

		insert.insert(con);
		updateFeed(feed);
	}

	void updateFeed(RSSFeed feed) {
		auto feedQuery = SQLQuery!(DB, q{
			select id from feeds where feeds.domain = {domain}
		})();
		feedQuery.domain = feed.link;
		auto id = feedQuery.query(con)[0].id;
		auto itemInsert = SQLInsertOrUpdate!(DB.Items,  "url", "feed", "title", "content", "time")();
		itemInsert.feed = id;
		foreach(item; feed.item)
		{		
			itemInsert.url = item.link;
			itemInsert.title = item.title;
			itemInsert.content = item.description;
			itemInsert.time  = item.time;
			itemInsert.insert(con);
		}
	}

	int getUser(string email)
	{
		auto query = SQLQuery!(DB, q{
			select id from users where email = {email}
		})();
		query.email = email;
		return query.query(con)[0].id;
	}

	void addSubscription(int user, int feed)
	{
		auto insert = q{
			insert ignore into subs(user, feed) values (?, ?);
		};
		con.execute(insert, user, feed);
	}

	auto getAllSources()
	{
		auto query = SQLQuery!(DB, q{
			select source from feeds;
		})();
		return query.query(con);
	}

	auto getSubscriptions(int user)
	{
		auto query = SQLQuery!(DB, q{
		   select id, title from feeds join subs
		   on feeds.id = subs.feed
		   where subs.user = {user}
		})();
		query.user = user;
		return query.query(con);
	}

	auto getFeed(int id) 
	{
		auto query = SQLQuery!(DB, q{
			select id, title from feeds
			where feeds.id = {id}
		})();
		query.id = id;
		return query.query(con)[0];
	}


	auto getFeed(string url) 
	{
		auto query = SQLQuery!(DB, q{
			select id, title from feeds
			where feeds.source = {source}
		})();
		query.source = url;
		return query.query(con)[0];
	}

	auto getAllUserItems(int user)
	{
		auto query = SQLQuery!(DB, q{
		   select items.url, items.title, items.content, items.time
		   from items join subs
		   on items.feed = subs.feed
		   where subs.user = {user}
		   order by items.time desc
		})();

		query.user = user;
		return query.query(con);
	}

	auto getItems(int id)
	{
		auto query = SQLQuery!(DB, q{
		   select url, items.title, content, items.time from items
		   join feeds on feeds.id = items.feed
		   where feeds.id = {id}
		   order by items.time desc
		})();
		query.id = id;
		return query.query(con);
	}
}
