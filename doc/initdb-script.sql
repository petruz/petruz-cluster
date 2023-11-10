CREATE DATABASE bitnami_keycloak;
CREATE DATABASE coder;
\c bitnami_keycloak;
CREATE USER bn_keycloak WITH PASSWORD 'pwd';
GRANT ALL PRIVILEGES ON SCHEMA public TO bn_keycloak;
\c coder;
CREATE USER coder WITH PASSWORD 'pwd';
GRANT ALL PRIVILEGES ON SCHEMA public TO coder;