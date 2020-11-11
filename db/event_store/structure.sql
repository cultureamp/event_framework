--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: refresh_events_sequence_stats(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refresh_events_sequence_stats() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

INSERT INTO events_sequence_stats(event_type, aggregate_type, max_sequence)
VALUES(NEW.event_type, NEW.aggregate_type, NEW.sequence)
ON CONFLICT(event_type, aggregate_type) DO
UPDATE SET max_sequence = NEW.sequence;

RETURN NULL;
END $$;


SET default_tablespace = '';

--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    sequence bigint NOT NULL,
    aggregate_sequence bigint NOT NULL,
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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

CREATE SEQUENCE public.events_sequence_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_sequence_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_sequence_seq OWNED BY public.events.sequence;


--
-- Name: events_sequence_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_sequence_stats (
    max_sequence bigint NOT NULL,
    aggregate_type character varying(255) NOT NULL,
    event_type character varying(255) NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    filename text NOT NULL
);


--
-- Name: events sequence; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN sequence SET DEFAULT nextval('public.events_sequence_seq'::regclass);


--
-- Name: events events_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_id_key UNIQUE (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (sequence);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (filename);


--
-- Name: events_aggregate_id_aggregate_sequence_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_aggregate_id_aggregate_sequence_index ON public.events USING btree (aggregate_id, aggregate_sequence);


--
-- Name: events_sequence_stats_aggregate_type_event_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_sequence_stats_aggregate_type_event_type_index ON public.events_sequence_stats USING btree (aggregate_type, event_type);


--
-- Name: events refresh_events_sequence_stats; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER refresh_events_sequence_stats AFTER INSERT ON public.events FOR EACH ROW EXECUTE PROCEDURE public.refresh_events_sequence_stats();


--
-- PostgreSQL database dump complete
--

