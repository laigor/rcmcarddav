-- Accounts table
CREATE SEQUENCE TABLE_PREFIXcarddav_accounts_seq
	INCREMENT BY 1
	NO MAXVALUE
	MINVALUE 1
	CACHE 1;

CREATE TABLE TABLE_PREFIXcarddav_accounts (
	id integer DEFAULT nextval('TABLE_PREFIXcarddav_accounts_seq'::text) PRIMARY KEY,
	accountname TEXT NOT NULL,
	username VARCHAR(255) NOT NULL,
	password TEXT NOT NULL,
	discovery_url TEXT,
	user_id integer NOT NULL REFERENCES TABLE_PREFIXusers (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
	last_discovered BIGINT NOT NULL DEFAULT 0, -- time stamp (seconds since epoch) of the addressbooks were last discovered
	rediscover_time INT NOT NULL DEFAULT 86400, -- time span (seconds) after that the addressbooks will be rediscovered, default 1d

	presetname VARCHAR(255), -- presetname

	flags SMALLINT NOT NULL DEFAULT 0,

	UNIQUE(user_id,presetname)
);
-- Note: no separate index on user_id, the UNIQUE index can be used

-- Addressbooks table
CREATE SEQUENCE TABLE_PREFIXcarddav_addressbooks_seq
	INCREMENT BY 1
	NO MAXVALUE
	MINVALUE 1
	CACHE 1;
CREATE TABLE TABLE_PREFIXcarddav_addressbooks (
	id integer DEFAULT nextval('TABLE_PREFIXcarddav_addressbooks_seq'::text) PRIMARY KEY,
	name TEXT NOT NULL,
	url TEXT NOT NULL,
	flags SMALLINT NOT NULL DEFAULT 5, -- default: discovered:2 | active:0 | bit 6: available_to_all (public/shared)
	last_updated BIGINT NOT NULL DEFAULT 0, -- time stamp (seconds since epoch) of the last update of the local database
	refresh_time INT NOT NULL DEFAULT 3600, -- time span (seconds) after that the local database will be refreshed, default 1h
	sync_token TEXT NOT NULL DEFAULT '', -- sync-token the server sent us for the last sync

	account_id integer NOT NULL REFERENCES TABLE_PREFIXcarddav_accounts (id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX TABLE_PREFIXcarddav_addressbooks_account_id_idx ON TABLE_PREFIXcarddav_addressbooks(account_id);

-- Contacts table
CREATE SEQUENCE TABLE_PREFIXcarddav_contacts_seq
	INCREMENT BY 1
	NO MAXVALUE
	MINVALUE 1
	CACHE 1;

CREATE TABLE TABLE_PREFIXcarddav_contacts (
	id integer DEFAULT nextval('TABLE_PREFIXcarddav_contacts_seq'::text) PRIMARY KEY,
	abook_id integer NOT NULL REFERENCES TABLE_PREFIXcarddav_addressbooks (id) ON DELETE CASCADE ON UPDATE CASCADE,
	name VARCHAR(255)     NOT NULL, -- display name
	email TEXT, -- ", " separated list of mail addresses
	firstname VARCHAR(255),
	surname VARCHAR(255),
	organization VARCHAR(255),
	showas VARCHAR(32) NOT NULL DEFAULT '', -- special display type (e.g., as a company)
	vcard text NOT NULL,        -- complete vcard
	etag VARCHAR(255) NOT NULL, -- entity tag, can be used to check if card changed on server
	uri  TEXT NOT NULL,  -- path of the card on the server
	cuid VARCHAR(255) NOT NULL,  -- unique identifier of the card within the collection

	UNIQUE(uri,abook_id),
	UNIQUE(cuid,abook_id)
);

CREATE INDEX TABLE_PREFIXcarddav_contacts_abook_id_idx ON TABLE_PREFIXcarddav_contacts(abook_id);

-- Custom subtypes table
CREATE SEQUENCE TABLE_PREFIXcarddav_xsubtypes_seq
	INCREMENT BY 1
	NO MAXVALUE
	MINVALUE 1
	CACHE 1;

CREATE TABLE TABLE_PREFIXcarddav_xsubtypes (
	id integer DEFAULT nextval('TABLE_PREFIXcarddav_xsubtypes_seq'::text) PRIMARY KEY,
	typename VARCHAR(128) NOT NULL,  -- name of the type
	subtype  VARCHAR(128) NOT NULL,  -- name of the subtype
	abook_id integer NOT NULL REFERENCES TABLE_PREFIXcarddav_addressbooks (id) ON DELETE CASCADE ON UPDATE CASCADE,
	UNIQUE (typename,subtype,abook_id)
);
CREATE INDEX TABLE_PREFIXcarddav_xsubtypes_abook_id_idx ON TABLE_PREFIXcarddav_xsubtypes(abook_id);

-- Groups table
CREATE SEQUENCE TABLE_PREFIXcarddav_groups_seq
	INCREMENT BY 1
	NO MAXVALUE
	MINVALUE 1
	CACHE 1;

CREATE TABLE TABLE_PREFIXcarddav_groups (
	id integer DEFAULT nextval('TABLE_PREFIXcarddav_groups_seq'::text) PRIMARY KEY,
	abook_id integer NOT NULL REFERENCES TABLE_PREFIXcarddav_addressbooks (id) ON DELETE CASCADE ON UPDATE CASCADE,
	name VARCHAR(255) NOT NULL, -- display name
	vcard TEXT,        -- complete vcard
	etag VARCHAR(255), -- entity tag, can be used to check if card changed on server
	uri  TEXT, -- path of the card on the server
	cuid VARCHAR(255), -- unique identifier of the card within the collection

	UNIQUE(uri,abook_id),
	UNIQUE(cuid,abook_id)
);
CREATE INDEX TABLE_PREFIXcarddav_groups_abook_id_idx ON TABLE_PREFIXcarddav_groups(abook_id);

-- Table for mapping group memberships
CREATE TABLE IF NOT EXISTS TABLE_PREFIXcarddav_group_user (
	group_id   integer NOT NULL,
	contact_id integer NOT NULL,

	PRIMARY KEY(group_id,contact_id),
	FOREIGN KEY(group_id) REFERENCES TABLE_PREFIXcarddav_groups(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(contact_id) REFERENCES TABLE_PREFIXcarddav_contacts(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX TABLE_PREFIXcarddav_group_user_contact_id_idx ON TABLE_PREFIXcarddav_group_user(contact_id);
CREATE INDEX TABLE_PREFIXcarddav_group_user_group_id_idx ON TABLE_PREFIXcarddav_group_user(group_id);

-- Table to record performed migrations and thereby schema version
CREATE SEQUENCE TABLE_PREFIXcarddav_migrations_seq
	INCREMENT BY 1
	NO MAXVALUE
	MINVALUE 1
	CACHE 1;

CREATE TABLE TABLE_PREFIXcarddav_migrations (
	id integer DEFAULT nextval('TABLE_PREFIXcarddav_migrations_seq'::text) PRIMARY KEY,
	filename VARCHAR(64) NOT NULL,
	processed_at TIMESTAMP NOT NULL DEFAULT now(),

	UNIQUE(filename)
);
