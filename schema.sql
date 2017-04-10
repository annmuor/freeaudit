CREATE TABLE hosts (
    hostname character varying(255) NOT NULL,
    os character varying(255),
    pkg_id integer[]
);


CREATE TABLE pkg (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


CREATE SEQUENCE pkg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE pkg_id_seq OWNED BY pkg.id;


CREATE TABLE v2p (
    pkg_id integer NOT NULL,
    vuln_id character varying(255) NOT NULL
);


CREATE TABLE vulners (
    id character varying(255) NOT NULL,
    cvss_score double precision DEFAULT 0.0 NOT NULL,
    cvss_vector character varying(255),
    description text,
    cvelist text
);


ALTER TABLE ONLY pkg ALTER COLUMN id SET DEFAULT nextval('pkg_id_seq'::regclass);


ALTER TABLE ONLY hosts
    ADD CONSTRAINT hosts_pkey PRIMARY KEY (hostname);

ALTER TABLE ONLY pkg
    ADD CONSTRAINT pkg_pkey PRIMARY KEY (id);

ALTER TABLE ONLY vulners
    ADD CONSTRAINT vulners_pkey PRIMARY KEY (id);

CREATE INDEX hosts_pkg_id_idx ON hosts USING gin (pkg_id);

CREATE UNIQUE INDEX pkg_name_idx ON pkg USING btree (name);

ALTER TABLE ONLY v2p
    ADD CONSTRAINT v2p_pkg_id_fkey FOREIGN KEY (pkg_id) REFERENCES pkg(id);

ALTER TABLE ONLY v2p
    ADD CONSTRAINT v2p_vuln_id_fkey FOREIGN KEY (vuln_id) REFERENCES vulners(id);
