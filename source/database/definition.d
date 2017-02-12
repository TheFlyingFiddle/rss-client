module database.definition;
import sql.attributes;
import std.datetime : DateTime;

alias URL = Varchar!(150);

@Database("rss_db")
struct RSSDatabase
{
	struct Users
	{
		@Primary @AutoIncrement
		int id;

		@Unique
		Varchar!(100) email;
	}

	struct Feeds
	{
		@Primary @AutoIncrement
		int id;

		@Unique
		URL source;

		URL domain;

		string title;
		string description;
		int ttl;
	}

	struct Items
	{
		@Primary
		URL url;

		@Foreign!(Feeds.id)
		int feed;

		string title;
		string content;
		DateTime time;
	}

	struct Subs
	{
		@Primary @Foreign!(Users.id)
		int user;

		@Primary @Foreign!(Feeds.id)
		int feed;
	}
}
