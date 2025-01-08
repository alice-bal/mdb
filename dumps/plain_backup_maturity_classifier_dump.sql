--
-- PostgreSQL database dump
--

-- Dumped from database version 15.10
-- Dumped by pg_dump version 15.10

-- Started on 2025-01-09 00:02:03

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
-- TOC entry 228 (class 1255 OID 18786)
-- Name: add_user_configuration(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_user_configuration(p_user_id integer, p_model_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO user_configurations (user_id, model_id)
    VALUES (p_user_id, p_model_id);
END;
$$;


ALTER FUNCTION public.add_user_configuration(p_user_id integer, p_model_id integer) OWNER TO postgres;

--
-- TOC entry 232 (class 1255 OID 18790)
-- Name: analyze_results(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.analyze_results(p_config_id integer) RETURNS TABLE(dimension_name character varying, average_score numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_name, AVG(cr.score) AS average_score
    FROM checklist_results cr
    JOIN sub_dimensions sd ON cr.sub_dimension_id = sd.sub_dimension_id
    JOIN dimensions d ON sd.dimension_id = d.dimension_id
    WHERE cr.config_id = p_config_id
    GROUP BY d.dimension_name;
END;
$$;


ALTER FUNCTION public.analyze_results(p_config_id integer) OWNER TO postgres;

--
-- TOC entry 230 (class 1255 OID 18788)
-- Name: generate_checklist(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_checklist(p_model_id integer) RETURNS TABLE(dimension_name character varying, sub_dimension_name character varying, criteria_text text, level integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_name, sd.sub_dimension_name, c.criteria_text, c.level
    FROM dimensions d
    JOIN sub_dimensions sd ON d.dimension_id = sd.dimension_id
    JOIN criteria c ON sd.sub_dimension_id = c.sub_dimension_id
    WHERE d.model_id = p_model_id;
END;
$$;


ALTER FUNCTION public.generate_checklist(p_model_id integer) OWNER TO postgres;

--
-- TOC entry 227 (class 1255 OID 18785)
-- Name: get_criteria_by_model(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_criteria_by_model(p_model_id integer) RETURNS TABLE(dimension_name character varying, sub_dimension_name character varying, criteria_text text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_name, sd.sub_dimension_name, c.criteria_text
    FROM dimensions d
    JOIN sub_dimensions sd ON d.dimension_id = sd.dimension_id
    JOIN criteria c ON sd.sub_dimension_id = c.sub_dimension_id
    WHERE d.model_id = p_model_id;
END;
$$;


ALTER FUNCTION public.get_criteria_by_model(p_model_id integer) OWNER TO postgres;

--
-- TOC entry 229 (class 1255 OID 18787)
-- Name: get_dimensions_by_model(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_dimensions_by_model(p_model_id integer) RETURNS TABLE(dimension_id integer, dimension_name character varying, description text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT d.dimension_id, d.dimension_name, d.description
    FROM dimensions d
    WHERE d.model_id = p_model_id;
END;
$$;


ALTER FUNCTION public.get_dimensions_by_model(p_model_id integer) OWNER TO postgres;

--
-- TOC entry 226 (class 1255 OID 18784)
-- Name: get_models(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_models() RETURNS TABLE(model_id integer, model_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT m.model_id, m.model_name
    FROM models m;
END;
$$;


ALTER FUNCTION public.get_models() OWNER TO postgres;

--
-- TOC entry 233 (class 1255 OID 18791)
-- Name: get_recommendations(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_recommendations(p_config_id integer) RETURNS TABLE(dimension_name character varying, sub_dimension_name character varying, criteria_text text, recommendations text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.dimension_name,
        sd.sub_dimension_name,
        c.criteria_text,
        CASE
            WHEN c.recommendations::jsonb ? cr.score::TEXT THEN c.recommendations::jsonb ->> cr.score::TEXT
            ELSE 'Рекомендация отсутствует'
        END AS recommendations
    FROM checklist_results cr
    JOIN sub_dimensions sd ON cr.sub_dimension_id = sd.sub_dimension_id
    JOIN dimensions d ON sd.dimension_id = d.dimension_id
    JOIN criteria c ON c.sub_dimension_id = cr.sub_dimension_id
    WHERE cr.config_id = p_config_id;
END;
$$;


ALTER FUNCTION public.get_recommendations(p_config_id integer) OWNER TO postgres;

--
-- TOC entry 231 (class 1255 OID 18789)
-- Name: save_checklist_result(integer, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.save_checklist_result(p_config_id integer, p_sub_dimension_id integer, p_score integer, p_comments text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO checklist_results (config_id, sub_dimension_id, score, comments)
    VALUES (p_config_id, p_sub_dimension_id, p_score, p_comments);
END;
$$;


ALTER FUNCTION public.save_checklist_result(p_config_id integer, p_sub_dimension_id integer, p_score integer, p_comments text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 18765)
-- Name: checklist_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.checklist_results (
    result_id integer NOT NULL,
    config_id integer,
    sub_dimension_id integer,
    score integer,
    comments text,
    CONSTRAINT checklist_results_score_check CHECK (((score >= 1) AND (score <= 5)))
);


ALTER TABLE public.checklist_results OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 18764)
-- Name: checklist_results_result_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.checklist_results_result_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.checklist_results_result_id_seq OWNER TO postgres;

--
-- TOC entry 3393 (class 0 OID 0)
-- Dependencies: 224
-- Name: checklist_results_result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.checklist_results_result_id_seq OWNED BY public.checklist_results.result_id;


--
-- TOC entry 221 (class 1259 OID 18737)
-- Name: criteria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.criteria (
    criteria_id integer NOT NULL,
    sub_dimension_id integer,
    criteria_text text NOT NULL,
    level integer,
    recommendations text,
    CONSTRAINT criteria_level_check CHECK (((level >= 1) AND (level <= 5)))
);


ALTER TABLE public.criteria OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 18736)
-- Name: criteria_criteria_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.criteria_criteria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.criteria_criteria_id_seq OWNER TO postgres;

--
-- TOC entry 3394 (class 0 OID 0)
-- Dependencies: 220
-- Name: criteria_criteria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.criteria_criteria_id_seq OWNED BY public.criteria.criteria_id;


--
-- TOC entry 217 (class 1259 OID 18709)
-- Name: dimensions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dimensions (
    dimension_id integer NOT NULL,
    model_id integer,
    dimension_name character varying(255) NOT NULL,
    description text
);


ALTER TABLE public.dimensions OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 18708)
-- Name: dimensions_dimension_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dimensions_dimension_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dimensions_dimension_id_seq OWNER TO postgres;

--
-- TOC entry 3395 (class 0 OID 0)
-- Dependencies: 216
-- Name: dimensions_dimension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dimensions_dimension_id_seq OWNED BY public.dimensions.dimension_id;


--
-- TOC entry 215 (class 1259 OID 18699)
-- Name: models; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.models (
    model_id integer NOT NULL,
    model_name character varying(255) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.models OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 18698)
-- Name: models_model_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.models_model_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.models_model_id_seq OWNER TO postgres;

--
-- TOC entry 3396 (class 0 OID 0)
-- Dependencies: 214
-- Name: models_model_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.models_model_id_seq OWNED BY public.models.model_id;


--
-- TOC entry 219 (class 1259 OID 18723)
-- Name: sub_dimensions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sub_dimensions (
    sub_dimension_id integer NOT NULL,
    dimension_id integer,
    sub_dimension_name character varying(255) NOT NULL,
    description text
);


ALTER TABLE public.sub_dimensions OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 18722)
-- Name: sub_dimensions_sub_dimension_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sub_dimensions_sub_dimension_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sub_dimensions_sub_dimension_id_seq OWNER TO postgres;

--
-- TOC entry 3397 (class 0 OID 0)
-- Dependencies: 218
-- Name: sub_dimensions_sub_dimension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sub_dimensions_sub_dimension_id_seq OWNED BY public.sub_dimensions.sub_dimension_id;


--
-- TOC entry 223 (class 1259 OID 18752)
-- Name: user_configurations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_configurations (
    config_id integer NOT NULL,
    user_id integer,
    model_id integer,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.user_configurations OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 18751)
-- Name: user_configurations_config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_configurations_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_configurations_config_id_seq OWNER TO postgres;

--
-- TOC entry 3398 (class 0 OID 0)
-- Dependencies: 222
-- Name: user_configurations_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_configurations_config_id_seq OWNED BY public.user_configurations.config_id;


--
-- TOC entry 3213 (class 2604 OID 18768)
-- Name: checklist_results result_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_results ALTER COLUMN result_id SET DEFAULT nextval('public.checklist_results_result_id_seq'::regclass);


--
-- TOC entry 3210 (class 2604 OID 18740)
-- Name: criteria criteria_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.criteria ALTER COLUMN criteria_id SET DEFAULT nextval('public.criteria_criteria_id_seq'::regclass);


--
-- TOC entry 3208 (class 2604 OID 18712)
-- Name: dimensions dimension_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dimensions ALTER COLUMN dimension_id SET DEFAULT nextval('public.dimensions_dimension_id_seq'::regclass);


--
-- TOC entry 3206 (class 2604 OID 18702)
-- Name: models model_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.models ALTER COLUMN model_id SET DEFAULT nextval('public.models_model_id_seq'::regclass);


--
-- TOC entry 3209 (class 2604 OID 18726)
-- Name: sub_dimensions sub_dimension_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sub_dimensions ALTER COLUMN sub_dimension_id SET DEFAULT nextval('public.sub_dimensions_sub_dimension_id_seq'::regclass);


--
-- TOC entry 3211 (class 2604 OID 18755)
-- Name: user_configurations config_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_configurations ALTER COLUMN config_id SET DEFAULT nextval('public.user_configurations_config_id_seq'::regclass);


--
-- TOC entry 3387 (class 0 OID 18765)
-- Dependencies: 225
-- Data for Name: checklist_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.checklist_results (result_id, config_id, sub_dimension_id, score, comments) VALUES (1, 1, 1, 4, 'Хороший прогресс в управлении портфелем');
INSERT INTO public.checklist_results (result_id, config_id, sub_dimension_id, score, comments) VALUES (2, 1, 2, 3, 'Средний уровень внедрения инноваций');
INSERT INTO public.checklist_results (result_id, config_id, sub_dimension_id, score, comments) VALUES (3, 1, 3, 2, 'Облачные технологии используются недостаточно активно');


--
-- TOC entry 3383 (class 0 OID 18737)
-- Dependencies: 221
-- Data for Name: criteria; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.criteria (criteria_id, sub_dimension_id, criteria_text, level, recommendations) VALUES (1, 1, 'Эффективность управления портфелем', 4, '{
    "1": "Создайте план управления портфелем проектов с четкими целями и метриками.",
    "2": "Обучите сотрудников методам управления портфелем.",
    "3": "Проведите регулярный аудит эффективности портфеля.",
    "4": "Используйте программное обеспечение для управления проектами.",
    "5": "Продолжайте использовать лучшие практики и делитесь опытом с коллегами."
}');
INSERT INTO public.criteria (criteria_id, sub_dimension_id, criteria_text, level, recommendations) VALUES (2, 1, 'Наличие четкой стратегии инноваций', 5, '{
    "1": "Создайте план управления портфелем проектов с четкими целями и метриками.",
    "2": "Обучите сотрудников методам управления портфелем.",
    "3": "Проведите регулярный аудит эффективности портфеля.",
    "4": "Используйте программное обеспечение для управления проектами.",
    "5": "Продолжайте использовать лучшие практики и делитесь опытом с коллегами."
}');
INSERT INTO public.criteria (criteria_id, sub_dimension_id, criteria_text, level, recommendations) VALUES (3, 2, 'Процент использования облачных технологий', 4, '{
    "1": "Сформулируйте инновационную стратегию, включающую цели и ожидаемые результаты.",
    "2": "Организуйте мозговой штурм для сбора идей.",
    "3": "Внедрите процессы для оценки и отбора инновационных идей.",
    "4": "Периодически пересматривайте стратегию на основе новых данных.",
    "5": "Расширьте масштабы инновационных проектов и отслеживайте их результаты."
}');


--
-- TOC entry 3379 (class 0 OID 18709)
-- Dependencies: 217
-- Data for Name: dimensions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.dimensions (dimension_id, model_id, dimension_name, description) VALUES (1, 1, 'Strategy', 'Оценка стратегии');
INSERT INTO public.dimensions (dimension_id, model_id, dimension_name, description) VALUES (2, 1, 'Technology', 'Оценка технологий');
INSERT INTO public.dimensions (dimension_id, model_id, dimension_name, description) VALUES (3, 2, 'Governance', 'Управление корпоративными ИТ');


--
-- TOC entry 3377 (class 0 OID 18699)
-- Dependencies: 215
-- Data for Name: models; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.models (model_id, model_name, description, created_at) VALUES (1, 'Digital Maturity Model', 'Оценка цифровой зрелости компании', '2025-01-08 23:53:32.922374');
INSERT INTO public.models (model_id, model_name, description, created_at) VALUES (2, 'COBIT', 'Модель управления корпоративными ИТ', '2025-01-08 23:53:32.922374');


--
-- TOC entry 3381 (class 0 OID 18723)
-- Dependencies: 219
-- Data for Name: sub_dimensions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sub_dimensions (sub_dimension_id, dimension_id, sub_dimension_name, description) VALUES (1, 1, 'Portfolio Management', 'Управление портфелем проектов');
INSERT INTO public.sub_dimensions (sub_dimension_id, dimension_id, sub_dimension_name, description) VALUES (2, 1, 'Innovation Strategy', 'Стратегия инноваций');
INSERT INTO public.sub_dimensions (sub_dimension_id, dimension_id, sub_dimension_name, description) VALUES (3, 2, 'Cloud Adoption', 'Использование облачных технологий');


--
-- TOC entry 3385 (class 0 OID 18752)
-- Dependencies: 223
-- Data for Name: user_configurations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_configurations (config_id, user_id, model_id, created_at) VALUES (1, 1, 1, '2025-01-08 23:53:47.31338');


--
-- TOC entry 3399 (class 0 OID 0)
-- Dependencies: 224
-- Name: checklist_results_result_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.checklist_results_result_id_seq', 3, true);


--
-- TOC entry 3400 (class 0 OID 0)
-- Dependencies: 220
-- Name: criteria_criteria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.criteria_criteria_id_seq', 3, true);


--
-- TOC entry 3401 (class 0 OID 0)
-- Dependencies: 216
-- Name: dimensions_dimension_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dimensions_dimension_id_seq', 3, true);


--
-- TOC entry 3402 (class 0 OID 0)
-- Dependencies: 214
-- Name: models_model_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.models_model_id_seq', 2, true);


--
-- TOC entry 3403 (class 0 OID 0)
-- Dependencies: 218
-- Name: sub_dimensions_sub_dimension_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sub_dimensions_sub_dimension_id_seq', 3, true);


--
-- TOC entry 3404 (class 0 OID 0)
-- Dependencies: 222
-- Name: user_configurations_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_configurations_config_id_seq', 1, true);


--
-- TOC entry 3227 (class 2606 OID 18773)
-- Name: checklist_results checklist_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_results
    ADD CONSTRAINT checklist_results_pkey PRIMARY KEY (result_id);


--
-- TOC entry 3223 (class 2606 OID 18745)
-- Name: criteria criteria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.criteria
    ADD CONSTRAINT criteria_pkey PRIMARY KEY (criteria_id);


--
-- TOC entry 3219 (class 2606 OID 18716)
-- Name: dimensions dimensions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dimensions
    ADD CONSTRAINT dimensions_pkey PRIMARY KEY (dimension_id);


--
-- TOC entry 3217 (class 2606 OID 18707)
-- Name: models models_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.models
    ADD CONSTRAINT models_pkey PRIMARY KEY (model_id);


--
-- TOC entry 3221 (class 2606 OID 18730)
-- Name: sub_dimensions sub_dimensions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sub_dimensions
    ADD CONSTRAINT sub_dimensions_pkey PRIMARY KEY (sub_dimension_id);


--
-- TOC entry 3225 (class 2606 OID 18758)
-- Name: user_configurations user_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_configurations
    ADD CONSTRAINT user_configurations_pkey PRIMARY KEY (config_id);


--
-- TOC entry 3232 (class 2606 OID 18774)
-- Name: checklist_results checklist_results_config_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_results
    ADD CONSTRAINT checklist_results_config_id_fkey FOREIGN KEY (config_id) REFERENCES public.user_configurations(config_id) ON DELETE CASCADE;


--
-- TOC entry 3233 (class 2606 OID 18779)
-- Name: checklist_results checklist_results_sub_dimension_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_results
    ADD CONSTRAINT checklist_results_sub_dimension_id_fkey FOREIGN KEY (sub_dimension_id) REFERENCES public.sub_dimensions(sub_dimension_id);


--
-- TOC entry 3230 (class 2606 OID 18746)
-- Name: criteria criteria_sub_dimension_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.criteria
    ADD CONSTRAINT criteria_sub_dimension_id_fkey FOREIGN KEY (sub_dimension_id) REFERENCES public.sub_dimensions(sub_dimension_id) ON DELETE CASCADE;


--
-- TOC entry 3228 (class 2606 OID 18717)
-- Name: dimensions dimensions_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dimensions
    ADD CONSTRAINT dimensions_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.models(model_id) ON DELETE CASCADE;


--
-- TOC entry 3229 (class 2606 OID 18731)
-- Name: sub_dimensions sub_dimensions_dimension_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sub_dimensions
    ADD CONSTRAINT sub_dimensions_dimension_id_fkey FOREIGN KEY (dimension_id) REFERENCES public.dimensions(dimension_id) ON DELETE CASCADE;


--
-- TOC entry 3231 (class 2606 OID 18759)
-- Name: user_configurations user_configurations_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_configurations
    ADD CONSTRAINT user_configurations_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.models(model_id);


-- Completed on 2025-01-09 00:02:03

--
-- PostgreSQL database dump complete
--

