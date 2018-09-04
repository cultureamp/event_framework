--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE bookmarks (
    lock_key bigint NOT NULL,
    name text NOT NULL,
    sequence bigint NOT NULL
);


--
-- Name: bookmarks_lock_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bookmarks_lock_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookmarks_lock_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bookmarks_lock_key_seq OWNED BY bookmarks.lock_key;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE events (
    sequence bigint NOT NULL,
    aggregate_sequence bigint NOT NULL,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    aggregate_id uuid NOT NULL,
    aggregate_type character varying(255) NOT NULL,
    event_type character varying(255) NOT NULL,
    body jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb NOT NULL
);


--
-- Name: events_sequence_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE events_sequence_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_sequence_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE events_sequence_seq OWNED BY events.sequence;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    filename text NOT NULL
);


--
-- Name: bookmarks lock_key; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookmarks ALTER COLUMN lock_key SET DEFAULT nextval('bookmarks_lock_key_seq'::regclass);


--
-- Name: events sequence; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY events ALTER COLUMN sequence SET DEFAULT nextval('events_sequence_seq'::regclass);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (name);


--
-- Name: events events_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_id_key UNIQUE (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (sequence);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (filename);


--
-- Name: events_aggregate_id_aggregate_sequence_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_aggregate_id_aggregate_sequence_index ON events USING btree (aggregate_id, aggregate_sequence);


--
-- Name: events_aggregate_type_event_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_aggregate_type_event_type_index ON events USING btree (aggregate_type, event_type);


--
-- PostgreSQL database dump complete
--

