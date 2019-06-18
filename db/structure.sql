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

SET default_with_oids = false;

--
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookmarks (
    lock_key bigint NOT NULL,
    name text NOT NULL,
    sequence bigint NOT NULL
);


--
-- Name: bookmarks_lock_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookmarks_lock_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookmarks_lock_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookmarks_lock_key_seq OWNED BY public.bookmarks.lock_key;


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
-- Name: question_codes_command_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_codes_command_projection (
    code text NOT NULL
);


--
-- Name: question_command_projection_a; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_command_projection_a (
    question_id uuid NOT NULL,
    survey_id uuid NOT NULL,
    account_id uuid NOT NULL
);


--
-- Name: question_command_projection_a_surveys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_command_projection_a_surveys (
    survey_id uuid NOT NULL,
    account_id uuid
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    filename text NOT NULL
);


--
-- Name: section_codes_command_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.section_codes_command_projection (
    code text NOT NULL
);


--
-- Name: section_command_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.section_command_projection (
    section_id uuid NOT NULL,
    survey_capture_layout_id uuid NOT NULL,
    status text NOT NULL,
    intended_purpose text NOT NULL
);


--
-- Name: section_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.section_questions (
    question_id uuid NOT NULL,
    section_id uuid,
    status text NOT NULL
);


--
-- Name: section_questions_correlation_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.section_questions_correlation_ids (
    event_id uuid NOT NULL,
    correlation_id uuid NOT NULL
);


--
-- Name: survey_command_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_command_projection (
    survey_id uuid NOT NULL,
    account_id uuid,
    survey_capture_layout_id uuid
);


--
-- Name: survey_detail_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_detail_questions (
    survey_id uuid NOT NULL,
    question_id uuid NOT NULL,
    section_id uuid,
    "order" integer,
    mandatory boolean NOT NULL,
    question_type text NOT NULL,
    code text NOT NULL,
    text jsonb NOT NULL,
    scale text,
    other_option boolean NOT NULL,
    selection_limit integer NOT NULL,
    status text NOT NULL,
    select_comments boolean NOT NULL
);


--
-- Name: survey_detail_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_detail_sections (
    section_id uuid NOT NULL,
    survey_id uuid NOT NULL,
    "order" integer NOT NULL,
    name jsonb NOT NULL,
    short_description jsonb NOT NULL,
    long_description jsonb NOT NULL,
    status text NOT NULL
);


--
-- Name: survey_detail_select_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_detail_select_options (
    select_option_id uuid NOT NULL,
    question_id uuid NOT NULL,
    value jsonb NOT NULL,
    "order" integer NOT NULL,
    status text NOT NULL
);


--
-- Name: survey_detail_surveys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_detail_surveys (
    survey_id uuid NOT NULL,
    survey_capture_layout_id uuid,
    name jsonb NOT NULL
);


--
-- Name: survey_names_projection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.survey_names_projection (
    survey_id uuid NOT NULL,
    account_id uuid NOT NULL,
    name text NOT NULL,
    locale text NOT NULL
);


--
-- Name: bookmarks lock_key; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks ALTER COLUMN lock_key SET DEFAULT nextval('public.bookmarks_lock_key_seq'::regclass);


--
-- Name: events sequence; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN sequence SET DEFAULT nextval('public.events_sequence_seq'::regclass);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (name);


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
-- Name: question_codes_command_projection question_codes_command_projection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_codes_command_projection
    ADD CONSTRAINT question_codes_command_projection_pkey PRIMARY KEY (code);


--
-- Name: question_command_projection_a question_command_projection_a_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_command_projection_a
    ADD CONSTRAINT question_command_projection_a_pkey PRIMARY KEY (question_id);


--
-- Name: question_command_projection_a_surveys question_command_projection_a_surveys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_command_projection_a_surveys
    ADD CONSTRAINT question_command_projection_a_surveys_pkey PRIMARY KEY (survey_id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (filename);


--
-- Name: section_codes_command_projection section_codes_command_projection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_codes_command_projection
    ADD CONSTRAINT section_codes_command_projection_pkey PRIMARY KEY (code);


--
-- Name: section_command_projection section_command_projection_section_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_command_projection
    ADD CONSTRAINT section_command_projection_section_id_key UNIQUE (section_id);


--
-- Name: section_questions_correlation_ids section_questions_correlation_ids_correlation_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_questions_correlation_ids
    ADD CONSTRAINT section_questions_correlation_ids_correlation_id_key UNIQUE (correlation_id);


--
-- Name: section_questions_correlation_ids section_questions_correlation_ids_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_questions_correlation_ids
    ADD CONSTRAINT section_questions_correlation_ids_event_id_key UNIQUE (event_id);


--
-- Name: section_questions section_questions_question_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.section_questions
    ADD CONSTRAINT section_questions_question_id_key UNIQUE (question_id);


--
-- Name: survey_command_projection survey_command_projection_survey_capture_layout_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_command_projection
    ADD CONSTRAINT survey_command_projection_survey_capture_layout_id_key UNIQUE (survey_capture_layout_id);


--
-- Name: survey_command_projection survey_command_projection_survey_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_command_projection
    ADD CONSTRAINT survey_command_projection_survey_id_key UNIQUE (survey_id);


--
-- Name: survey_detail_questions survey_detail_questions_question_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_detail_questions
    ADD CONSTRAINT survey_detail_questions_question_id_key UNIQUE (question_id);


--
-- Name: survey_detail_sections survey_detail_sections_section_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_detail_sections
    ADD CONSTRAINT survey_detail_sections_section_id_key UNIQUE (section_id);


--
-- Name: survey_detail_select_options survey_detail_select_options_select_option_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_detail_select_options
    ADD CONSTRAINT survey_detail_select_options_select_option_id_key UNIQUE (select_option_id);


--
-- Name: survey_detail_surveys survey_detail_surveys_survey_capture_layout_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_detail_surveys
    ADD CONSTRAINT survey_detail_surveys_survey_capture_layout_id_key UNIQUE (survey_capture_layout_id);


--
-- Name: survey_detail_surveys survey_detail_surveys_survey_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.survey_detail_surveys
    ADD CONSTRAINT survey_detail_surveys_survey_id_key UNIQUE (survey_id);


--
-- Name: events_aggregate_id_aggregate_sequence_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_aggregate_id_aggregate_sequence_index ON public.events USING btree (aggregate_id, aggregate_sequence);


--
-- Name: events_aggregate_type_event_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_aggregate_type_event_type_index ON public.events USING btree (aggregate_type, event_type);


--
-- Name: events_sequence_stats_aggregate_type_event_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX events_sequence_stats_aggregate_type_event_type_index ON public.events_sequence_stats USING btree (aggregate_type, event_type);


--
-- Name: section_questions_section_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX section_questions_section_id_index ON public.section_questions USING btree (section_id);


--
-- Name: survey_detail_questions_section_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX survey_detail_questions_section_id_index ON public.survey_detail_questions USING btree (section_id);


--
-- Name: survey_detail_select_options_question_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX survey_detail_select_options_question_id_index ON public.survey_detail_select_options USING btree (question_id);


--
-- Name: survey_names_projection_survey_id_locale_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX survey_names_projection_survey_id_locale_index ON public.survey_names_projection USING btree (survey_id, locale);


--
-- Name: events refresh_events_sequence_stats; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER refresh_events_sequence_stats AFTER INSERT ON public.events FOR EACH ROW EXECUTE PROCEDURE public.refresh_events_sequence_stats();


--
-- PostgreSQL database dump complete
--

