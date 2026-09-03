CREATE TABLE project_task
(
    id                                  character varying(64) NOT NULL,
    clientreferenceid                   character varying(64),
    tenantid                            character varying(1000),
    projectid                           character varying(64),
    projectbeneficiaryid                character varying(64),
    projectbeneficiaryclientreferenceid character varying(64),
    plannedstartdate                    bigint,
    plannedenddate                      bigint,
    actualstartdate                     bigint,
    actualenddate                       bigint,
    addressid                           character varying(1000),
    additionaldetails                   jsonb,
    createdby                           character varying(64),
    createdtime                         bigint,
    lastmodifiedby                      character varying(64),
    lastmodifiedtime                    bigint,
    rowversion                          bigint,
    isdeleted                           boolean,
    clientcreatedtime                   bigint,
    clientlastmodifiedtime              bigint,
    clientcreatedby                     character varying(64),
    clientlastmodifiedby                character varying(64),
    status                              character varying(1000),

    CONSTRAINT uk_project_task_id
        PRIMARY KEY (id),

    CONSTRAINT uk_task_clientreference_id
        UNIQUE (clientreferenceid)
);

CREATE INDEX idx_project_task_actualenddate
    ON project_task (actualenddate);

CREATE INDEX idx_project_task_actualstartdate
    ON project_task (actualstartdate);

CREATE INDEX idx_project_task_clientreferenceid
    ON project_task (clientreferenceid);

CREATE INDEX idx_project_task_createdby
    ON project_task (createdby);

CREATE INDEX idx_project_task_plannedenddate
    ON project_task (plannedenddate);

CREATE INDEX idx_project_task_plannedstartdate
    ON project_task (plannedstartdate);

CREATE INDEX idx_project_task_projectbeneficiaryclientreferenceid
    ON project_task (projectbeneficiaryclientreferenceid);

CREATE INDEX idx_project_task_projectbeneficiaryid
    ON project_task (projectbeneficiaryid);

CREATE INDEX idx_project_task_projectid
    ON project_task (projectid);

CREATE INDEX idx_project_task_status
    ON project_task (status);


CREATE TABLE project
(
    id                character varying(64) NOT NULL,
    tenantid          character varying(1000),
    projectnumber     character varying(128) NOT NULL,
    name              character varying(128),
    projecttypeid     character varying(64),
    projecttype       character varying(64),
    projectsubtype    character varying(128) NOT NULL,
    department        character varying(64)  NOT NULL,
    description       character varying(256) NOT NULL,
    referenceid       character varying(100) NOT NULL,
    natureofwork      character varying(64),
    addressid         character varying(64),
    startdate         bigint,
    enddate           bigint,
    istaskenabled     boolean,
    parent            character varying(64),
    projecthierarchy  text,
    additionaldetails jsonb,
    createdby         character varying(64),
    createdtime       bigint,
    lastmodifiedby    character varying(64),
    lastmodifiedtime  bigint,
    rowversion        bigint,
    isdeleted         boolean,

    CONSTRAINT uk_project_id
        PRIMARY KEY (id)
);

CREATE INDEX idx_project_tenantid
    ON project (tenantid);

CREATE INDEX idx_project_startdate
    ON project (startdate);

CREATE INDEX idx_project_enddate
    ON project (enddate);

CREATE INDEX idx_project_istaskenabled
    ON project (istaskenabled);

CREATE INDEX idx_project_parent
    ON project (parent);

CREATE INDEX idx_project_projecttypeid
    ON project (projecttypeid);

CREATE INDEX idx_project_projectsubtype
    ON project (projectsubtype);

CREATE INDEX idx_project_department
    ON project (department);

CREATE INDEX idx_project_referenceid
    ON project (referenceid);

CREATE TABLE project_target
(
    id               character varying(64),
    projectId        character varying(64) NOT NULL,
    beneficiaryType  character varying(64),
    totalNo          bigint,
    targetNo         bigint,
    isDeleted        boolean,
    createdBy        character varying(64) NOT NULL,
    lastModifiedBy   character varying(64),
    createdTime      bigint,
    lastModifiedTime bigint,
    CONSTRAINT uk_project_target_id PRIMARY KEY (id)
);

CREATE TABLE project_address
(
    id               character varying(64) NOT NULL,
    tenantid         character varying(64) NOT NULL,
    projectid        character varying(64) NOT NULL,
    doorno           character varying(64),
    latitude         double precision,
    longitude        double precision,
    locationaccuracy bigint,
    type             character varying(64),
    addressline1     character varying(256),
    addressline2     character varying(256),
    landmark         character varying(256),
    city             character varying(256),
    pincode          character varying(64),
    buildingname     character varying(256),
    street           character varying(256),
    boundary         character varying(128),
    boundarytype     character varying(64),

    CONSTRAINT uk_project_address_id PRIMARY KEY (id)
);

CREATE INDEX idx_project_boundary
    ON project_address (boundary);



CREATE TABLE project_beneficiary
(
    id                           character varying(64) NOT NULL,
    tenantid                     character varying(1000),
    projectid                    character varying(64),
    beneficiaryid                character varying(64),
    clientreferenceid            character varying(64),
    beneficiaryclientreferenceid character varying(64),
    createdby                    character varying(64),
    lastmodifiedby               character varying(64),
    dateofregistration           bigint,
    additionaldetails            jsonb,
    createdtime                   bigint,
    lastmodifiedtime              bigint,
    rowversion                    bigint,
    isdeleted                     boolean,
    clientcreatedtime              bigint,
    clientlastmodifiedtime         bigint,
    clientcreatedby                character varying(64),
    clientlastmodifiedby           character varying(64),
    tag                            character varying(1000),

    CONSTRAINT uk_project_beneficiary_id
        PRIMARY KEY (id),

    CONSTRAINT project_beneficiary_vouchertag_key
        UNIQUE (tag),

    CONSTRAINT uk_project_beneficiary_client_reference_id
        UNIQUE (clientreferenceid)
);

CREATE INDEX idx_project_beneficiary_beneficiaryclientreferenceid
    ON project_beneficiary (beneficiaryclientreferenceid);

CREATE INDEX idx_project_beneficiary_beneficiaryid
    ON project_beneficiary (beneficiaryid);

CREATE INDEX idx_project_beneficiary_clientreferenceid
    ON project_beneficiary (clientreferenceid);

CREATE INDEX idx_project_beneficiary_dateofregistration
    ON project_beneficiary (dateofregistration);

CREATE INDEX idx_project_beneficiary_projectid
    ON project_beneficiary (projectid);

CREATE INDEX idx_project_beneficiary_tenantid
    ON project_beneficiary (tenantid);


-- address is distinct from project_address. project_task.addressid points here,
-- while project_address is keyed by projectid. This table carries localitycode
-- and clientreferenceid; project_address carries boundary/boundarytype instead
-- and has no client reference.
--
-- Declared by THREE services -- project, household and individual -- each with
-- CREATE TABLE IF NOT EXISTS, so only the first to run actually creates it. The
-- base definition is identical in all three, but the alters are not: wardcode
-- below is added only by the individual service (V20230302155500), so an
-- address table created in a database where the individual service has not
-- migrated will not have that column.
CREATE TABLE address
(
    id                character varying(64) NOT NULL,
    tenantid          character varying(1000),
    doorno            character varying(64),
    latitude          double precision,
    longitude         double precision,
    locationaccuracy  integer,
    type              character varying(64),
    addressline1      character varying(256),
    addressline2      character varying(256),
    landmark          character varying(256),
    city              character varying(256),
    pincode           character varying(64),
    buildingname      character varying(256),
    street            character varying(256),
    localitycode      character varying(256),
    clientreferenceid character varying(64),
    wardcode          character varying(256),

    CONSTRAINT uk_address_id
        PRIMARY KEY (id),

    CONSTRAINT address_clientreferenceid_key
        UNIQUE (clientreferenceid)
);

CREATE INDEX idx_localitycode
    ON address (localitycode);


CREATE TABLE project_staff
(
    id                character varying(64) NOT NULL,
    tenantid          character varying(1000),
    projectid         character varying(64),
    staffid           character varying(64),
    startdate         bigint,
    enddate           bigint,
    additionaldetails jsonb,
    createdby         character varying(64),
    lastmodifiedby    character varying(64),
    createdtime       bigint,
    lastmodifiedtime  bigint,
    rowversion        bigint,
    isdeleted         boolean,

    CONSTRAINT uk_project_staff_id
        PRIMARY KEY (id)
);

CREATE INDEX idx_project_staff_tenantid
    ON project_staff (tenantid);

CREATE INDEX idx_project_staff_staffid
    ON project_staff (staffid);

CREATE INDEX idx_project_staff_projectid
    ON project_staff (projectid);

CREATE INDEX idx_project_staff_startdate
    ON project_staff (startdate);

CREATE INDEX idx_project_staff_enddate
    ON project_staff (enddate);


CREATE TABLE project_facility
(
    id                character varying(64) NOT NULL,
    tenantid          character varying(1000),
    projectid         character varying(64),
    facilityid        character varying(64),
    additionaldetails jsonb,
    createdby         character varying(64),
    lastmodifiedby    character varying(64),
    createdtime       bigint,
    lastmodifiedtime  bigint,
    rowversion        bigint,
    isdeleted         boolean,

    CONSTRAINT uk_project_facility_id
        PRIMARY KEY (id)
);

CREATE INDEX idx_project_facility_tenantid
    ON project_facility (tenantid);

CREATE INDEX idx_project_facility_facilityid
    ON project_facility (facilityid);

CREATE INDEX idx_project_facility_projectid
    ON project_facility (projectid);


CREATE TABLE project_resource
(
    id                character varying(64) NOT NULL,
    tenantid          character varying(1000),
    projectid         character varying(64),
    productvariantid  character varying(64),
    isbaseunitvariant boolean,
    type              character varying(1000),
    startdate         bigint,
    enddate           bigint,
    createdby         character varying(64),
    createdtime       bigint,
    lastmodifiedby    character varying(64),
    lastmodifiedtime  bigint,
    rowversion        bigint,
    isdeleted         boolean,

    CONSTRAINT uk_project_resource_id
        PRIMARY KEY (id)
);

CREATE INDEX idx_project_resource_projectid
    ON project_resource (projectid);


-- project_document and project_target carry no rowversion and no isdeleted
-- (project_document only), unlike the other project child tables. The DAG's
-- soft-delete and version handling must account for that.
CREATE TABLE project_document
(
    id                character varying(64) NOT NULL,
    projectid         character varying(64)  NOT NULL,
    documenttype      character varying(256),
    filestoreid       character varying(256) NOT NULL,
    documentuid       character varying(64),
    additionaldetails jsonb,
    status            character varying(64),
    createdby         character varying(64)  NOT NULL,
    lastmodifiedby    character varying(64),
    createdtime       bigint,
    lastmodifiedtime  bigint,

    CONSTRAINT uk_project_document_id
        PRIMARY KEY (id)
);


CREATE TABLE project_target
(
    id               character varying(64) NOT NULL,
    projectid        character varying(64) NOT NULL,
    beneficiarytype  character varying(64),
    totalno          bigint,
    targetno         bigint,
    isdeleted        boolean,
    createdby        character varying(64) NOT NULL,
    lastmodifiedby   character varying(64),
    createdtime      bigint,
    lastmodifiedtime bigint,

    CONSTRAINT uk_project_target_id
        PRIMARY KEY (id)
);


-- task_resource has no rowversion and no client audit columns, unlike
-- project_task which it hangs off via taskid. quantity was widened from bigint
-- to double precision, so it arrives as a float in the change events.
CREATE TABLE task_resource
(
    id                   character varying(64) NOT NULL,
    tenantid             character varying(1000),
    productvariantid     character varying(64),
    taskid               character varying(64),
    quantity             double precision,
    isdelivered          boolean,
    reasonifnotdelivered character varying(1000),
    createdby            character varying(64),
    createdtime          bigint,
    lastmodifiedby       character varying(64),
    lastmodifiedtime     bigint,
    isdeleted            boolean,
    clientreferenceid    character varying(64),
    additionaldetails    jsonb,

    CONSTRAINT uk_task_resource_id
        PRIMARY KEY (id),

    CONSTRAINT task_resource_clientreferenceid_key
        UNIQUE (clientreferenceid)
);

CREATE INDEX idx_task_resource_taskid
    ON task_resource (taskid);


CREATE TABLE user_location
(
    id                     character varying(64) NOT NULL,
    clientreferenceid      character varying(64),
    tenantid               character varying(1000) NOT NULL,
    projectid              character varying(64)   NOT NULL,
    latitude               double precision        NOT NULL,
    longitude              double precision        NOT NULL,
    locationaccuracy       integer                 NOT NULL,
    boundarycode           character varying(256)  NOT NULL,
    action                 character varying(256),
    createdby              character varying(64)   NOT NULL,
    createdtime            bigint                  NOT NULL,
    lastmodifiedby         character varying(64)   NOT NULL,
    lastmodifiedtime       bigint                  NOT NULL,
    clientcreatedtime      bigint,
    clientlastmodifiedtime bigint,
    clientcreatedby        character varying(64),
    clientlastmodifiedby   character varying(64),
    additionaldetails      jsonb,

    CONSTRAINT pk_user_location
        PRIMARY KEY (id)
);

CREATE INDEX idx_user_location_clientcreatedby
    ON user_location (clientcreatedby);


CREATE TABLE user_action
(
    id                     character varying(64) NOT NULL,
    clientreferenceid      character varying(64),
    tenantid               character varying(1000) NOT NULL,
    projectid              character varying(64)   NOT NULL,
    latitude               double precision        NOT NULL,
    longitude              double precision        NOT NULL,
    locationaccuracy       integer                 NOT NULL,
    boundarycode           character varying(256)  NOT NULL,
    action                 character varying(256)  NOT NULL,
    beneficiarytag         character varying(64),
    resourcetag            character varying(64),
    status                 character varying(1000),
    additionaldetails      jsonb,
    createdby              character varying(64)   NOT NULL,
    createdtime            bigint                  NOT NULL,
    lastmodifiedby         character varying(64)   NOT NULL,
    lastmodifiedtime       bigint                  NOT NULL,
    clientcreatedtime      bigint,
    clientlastmodifiedtime bigint,
    clientcreatedby        character varying(64),
    clientlastmodifiedby   character varying(64),
    rowversion             bigint,

    CONSTRAINT pk_user_action_id
        PRIMARY KEY (id),

    CONSTRAINT uk_user_action_clientreference_id
        UNIQUE (clientreferenceid)
);

CREATE INDEX idx_user_action_projectid_clientcreatedby
    ON user_action (projectid, clientcreatedby);


-- ---------------------------------------------------------------------------
-- household service
-- health-services/household/src/main/resources/db/migration/main/
--
-- The household service also declares an ADDRESS table, with a definition
-- byte-identical to the project service's (same columns, same clientreferenceid
-- UNIQUE alter, same idx_localitycode). Both use CREATE TABLE IF NOT EXISTS, so
-- it is defined once above and shared here rather than duplicated.
--
-- Index definitions below reflect the post-DROP state. Several indexes created
-- by earlier migrations were dropped by later ones -- notably
-- V20250603132035__tenant_composit_indexes.sql, which replaced single-column id
-- and clientreferenceid indexes with (col, tenantid) composites. Only surviving
-- indexes are listed.
-- ---------------------------------------------------------------------------
CREATE TABLE household
(
    id                     character varying(64) NOT NULL,
    tenantid               character varying(1000),
    clientreferenceid      character varying(1000),
    numberofmembers        integer,
    householdtype          character varying(64) DEFAULT 'FAMILY' NOT NULL,
    addressid              character varying(1000),
    additionaldetails      jsonb,
    createdby              character varying(64),
    lastmodifiedby         character varying(64),
    createdtime            bigint,
    lastmodifiedtime       bigint,
    clientcreatedtime      bigint,
    clientlastmodifiedtime bigint,
    clientcreatedby        character varying(64),
    clientlastmodifiedby   character varying(64),
    rowversion             bigint,
    isdeleted              boolean,

    CONSTRAINT uk_household_id
        PRIMARY KEY (id),

    CONSTRAINT uk_household_client_reference_id
        UNIQUE (clientreferenceid)
);

CREATE INDEX idx_household_tenantid_isdeleted_addressid
    ON household (tenantid, isdeleted, addressid);

CREATE INDEX idx_household_clientreferenceid_tenantid
    ON household (clientreferenceid, tenantid);

CREATE INDEX idx_household_id_tenantid
    ON household (id, tenantid);


-- WARNING: household_member has NO PRIMARY KEY and no unique constraint. Its
-- creating migration (V20230117172150) declares none, and no later migration
-- adds one -- confirmed against the live database, where \d shows only six
-- non-unique btree indexes.
--
-- PostgreSQL therefore gives it the default replica identity, which resolves to
-- nothing usable, so Debezium CANNOT capture UPDATE or DELETE on this table and
-- PostgreSQL will reject UPDATEs once it is added to a publication.
--
--   ALTER TABLE household_member REPLICA IDENTITY FULL;
--
-- is the ONLY option here. The usual alternative -- a unique index plus REPLICA
-- IDENTITY USING INDEX -- cannot work: `id` is nullable in the live database
-- (see below), and PostgreSQL refuses a nullable column in a replica-identity
-- index. Run the ALTER before enabling CDC on this table.
--
-- Column order and the nullable `id` below mirror the live database. `id` being
-- nullable is the source's own doing, not a transcription slip -- the creating
-- migration declared it NOT NULL and something later dropped that.
CREATE TABLE household_member
(
    id                          character varying(64),
    tenantid                    character varying(1000),
    individualid                character varying(64),
    individualclientreferenceid character varying(64),
    householdid                 character varying(64),
    householdclientreferenceid  character varying(64),
    isheadofhousehold           boolean,
    additionaldetails           jsonb,
    createdby                   character varying(64),
    createdtime                 bigint,
    lastmodifiedby              character varying(64),
    lastmodifiedtime            bigint,
    rowversion                  bigint,
    isdeleted                   boolean,
    clientcreatedtime           bigint,
    clientlastmodifiedtime      bigint,
    clientcreatedby             character varying(64),
    clientlastmodifiedby        character varying(64),
    clientreferenceid           character varying(256) NOT NULL
);

CREATE INDEX idx_household_member_householdid
    ON household_member (householdid);

CREATE INDEX idx_household_member_householdclientreferenceid
    ON household_member (householdclientreferenceid);

CREATE INDEX idx_household_member_individualid
    ON household_member (individualid);

CREATE INDEX idx_household_member_individualclientreferenceid
    ON household_member (individualclientreferenceid);

CREATE INDEX idx_household_member_isheadofhousehold
    ON household_member (isheadofhousehold);

CREATE INDEX idx_household_member_tenantid
    ON household_member (tenantid);

-- These two are declared by V20250603132035__tenant_composit_indexes.sql and are
-- NOT present in the live database -- \d shows only the six single-column
-- indexes above. Kept here because the file tracks the migration set; neither
-- affects CDC or the Bronze layer.
CREATE INDEX idx_householdmember_clientreferenceid_tenantid
    ON household_member (clientreferenceid, tenantid);

CREATE INDEX idx_householdmember_id_tenantid
    ON household_member (id, tenantid);


-- selfid / selfclientreferenceid were created as householdmemberid /
-- householdmemberclientreferenceid and renamed by V20250403022035. The CHECK
-- constraint enforces that at least one of the two relative references is set,
-- so neither column is individually NOT NULL.
CREATE TABLE household_member_relationship
(
    id                        character varying(64) NOT NULL,
    clientreferenceid         character varying(64),
    tenantid                  character varying(1000) NOT NULL,
    selfid                    character varying(64)   NOT NULL,
    selfclientreferenceid     character varying(64),
    relativeid                character varying(64),
    relativeclientreferenceid character varying(64),
    relationshiptype          character varying(64)   NOT NULL,
    createdby                 character varying(64),
    createdtime               bigint,
    lastmodifiedby            character varying(64),
    lastmodifiedtime          bigint,
    clientcreatedby           character varying(64),
    clientcreatedtime         bigint,
    clientlastmodifiedby      character varying(64),
    clientlastmodifiedtime    bigint,
    rowversion                bigint,
    isdeleted                 boolean,

    CONSTRAINT uk_household_member_relationship_id
        PRIMARY KEY (id),

    CONSTRAINT uk_household_member_relationship_client_reference_id
        UNIQUE (clientreferenceid),

    CONSTRAINT hmr_relative_id_not_null
        CHECK (relativeid IS NOT NULL OR relativeclientreferenceid IS NOT NULL)
);

CREATE INDEX idx_householdmemberrelationship_selfid_tenantid
    ON household_member_relationship (selfid, tenantid);

CREATE INDEX idx_householdmemberrelationship_selfclientreferenceid_tenantid
    ON household_member_relationship (selfclientreferenceid, tenantid);


-- ---------------------------------------------------------------------------
-- individual service
-- health-services/individual/src/main/resources/db/migration/main/
--
-- This service also declares the shared ADDRESS table defined above, and is the
-- only one of the three that adds wardcode to it.
--
-- NOTE ON TEMPORAL TYPES: individual.dateofbirth is a DATE column -- the only
-- non-BIGINT temporal column anywhere in this file. The assumption stated in
-- the header comment (all times are BIGINT epoch millis, so time.precision.mode
-- needs no handling) does NOT hold for it. Debezium emits DATE as
-- io.debezium.time.Date, an INT32 count of days since epoch, not milliseconds.
-- The Silver-layer mapping must convert it explicitly rather than reusing the
-- epoch-millis path.
--
-- Columns below reflect the post-DROP state: individual.password was added by
-- V20230515111200 and dropped by V20250303122000; individual_address.rowversion
-- and individual_identifier.rowversion were dropped by V20230120125300.
-- ---------------------------------------------------------------------------
CREATE TABLE individual
(
    id                     character varying(64) NOT NULL,
    userid                 character varying(64),
    useruuid               character varying(64),
    clientreferenceid      character varying(64),
    individualid           character varying(64),
    tenantid               character varying(1000),
    givenname              character varying(200),
    familyname             character varying(200),
    othernames             character varying(200),
    dateofbirth            date,
    gender                 character varying(20),
    bloodgroup             character varying(10),
    mobilenumber           character varying(256),
    altcontactnumber       character varying(20),
    email                  character varying(200),
    fathername             character varying(100),
    husbandname            character varying(100),
    relationship           character varying(100),
    photo                  text,
    type                   character varying(64),
    username               character varying(64),
    roles                  jsonb,
    issystemuser           boolean,
    issystemuseractive     boolean,
    additionaldetails      jsonb,
    createdby              character varying(64),
    lastmodifiedby         character varying(64),
    createdtime            bigint,
    lastmodifiedtime       bigint,
    clientcreatedtime      bigint,
    clientlastmodifiedtime bigint,
    clientcreatedby        character varying(64),
    clientlastmodifiedby   character varying(64),
    rowversion             bigint,
    isdeleted              boolean,

    CONSTRAINT uk_individual_id
        PRIMARY KEY (id),

    CONSTRAINT uk_individual_client_reference_id
        UNIQUE (clientreferenceid),

    CONSTRAINT individual_individualid_key
        UNIQUE (individualid)
);

CREATE INDEX idx_individual_clientreferenceid
    ON individual (clientreferenceid);

CREATE INDEX idx_individual_givenname
    ON individual (givenname);

CREATE INDEX idx_individual_familyname
    ON individual (familyname);

CREATE INDEX idx_individual_othernames
    ON individual (othernames);

CREATE INDEX idx_individual_dateofbirth
    ON individual (dateofbirth);

CREATE INDEX idx_individual_gender
    ON individual (gender);

CREATE INDEX idx_individual_iid_tenant_is_deleted
    ON individual (individualid, tenantid, isdeleted);

CREATE INDEX idx_individual_createdtime
    ON individual (createdtime);


-- WARNING: individual_address has NO PRIMARY KEY. Its unique constraint spans
-- (individualid, addressid, type, isdeleted), all of which are nullable, so it
-- cannot back a REPLICA IDENTITY USING INDEX either. Set REPLICA IDENTITY FULL
-- before publishing this table, or Debezium will not capture UPDATE/DELETE.
-- See the household_member note above -- same problem, same options.
CREATE TABLE individual_address
(
    individualid     character varying(64),
    addressid        character varying(64),
    type             character varying(64),
    createdby        character varying(64),
    lastmodifiedby   character varying(64),
    createdtime      bigint,
    lastmodifiedtime bigint,
    isdeleted        boolean,

    CONSTRAINT uk_individual_address_mapping
        UNIQUE (individualid, addressid, type, isdeleted)
);

CREATE INDEX idx_individual_address_individual_type_lastmodified
    ON individual_address (individualid, type, lastmodifiedtime);

CREATE INDEX idx_individual_address_covering
    ON individual_address (individualid, type, lastmodifiedtime, addressid, isdeleted);


-- Column order here is unusual because id was dropped by V20230120120600 and
-- re-added at the end by V20230123172500, taking the trailing position along
-- with the two client reference columns.
--
-- individualclientreferenceid was originally named clientreferenceid; it was
-- renamed by V20250508122000, which then added a NEW clientreferenceid column
-- defaulting to gen_random_uuid()::text. That default needs pgcrypto on
-- PostgreSQL 12 and earlier; it is built in from PostgreSQL 13 onward.
CREATE TABLE individual_identifier
(
    individualid                character varying(64),
    identifiertype              character varying(64),
    identifierid                character varying(256),
    createdby                   character varying(64),
    lastmodifiedby              character varying(64),
    createdtime                 bigint,
    lastmodifiedtime            bigint,
    isdeleted                   boolean,
    id                          character varying(64) NOT NULL,
    individualclientreferenceid character varying(64),
    clientreferenceid           character varying(64) DEFAULT gen_random_uuid()::text,

    CONSTRAINT individual_identifier_pkey
        PRIMARY KEY (id),

    CONSTRAINT uk_individual_identifier_mapping
        UNIQUE (individualid, identifiertype, isdeleted),

    CONSTRAINT individual_identifier_clientreferenceid_key
        UNIQUE (clientreferenceid)
);

CREATE INDEX idx_individual_identifier_individualid
    ON individual_identifier (individualid);

CREATE INDEX idx_individual_identifier_identifiertype
    ON individual_identifier (identifiertype);

CREATE INDEX idx_individual_identifier_identifierid
    ON individual_identifier (identifierid);

CREATE INDEX idx_individual_identifier_isdeleted
    ON individual_identifier (isdeleted);

CREATE INDEX idx_individual_identifier_createdby
    ON individual_identifier (createdby);

CREATE INDEX idx_individual_identifier_lastmodifiedby
    ON individual_identifier (lastmodifiedby);

CREATE INDEX idx_individual_identifier_createdtime
    ON individual_identifier (createdtime);

CREATE INDEX idx_individual_identifier_lastmodifiedtime
    ON individual_identifier (lastmodifiedtime);


CREATE TABLE individual_skill
(
    id                character varying(64) NOT NULL,
    individualid      character varying(64),
    type              character varying(64),
    level             character varying(64),
    experience        character varying(64),
    createdby         character varying(64),
    lastmodifiedby    character varying(64),
    createdtime       bigint,
    lastmodifiedtime  bigint,
    isdeleted         boolean,
    clientreferenceid character varying(64),

    CONSTRAINT uk_individual_skill_id
        PRIMARY KEY (id),

    CONSTRAINT individual_skill_clientreferenceid_key
        UNIQUE (clientreferenceid)
);

CREATE INDEX idx_individual_skills_iid
    ON individual_skill (individualid);

CREATE INDEX idx_individual_skills_iid_is_deleted
    ON individual_skill (individualid, isdeleted);


-- WARNING: household_individual has NO PRIMARY KEY and no unique constraint at
-- all, so it has no usable replica identity. REPLICA IDENTITY FULL is the only
-- option here short of altering the schema.
--
-- This table overlaps heavily with household_member in the household service
-- (same individual/household reference pair, same isheadofhousehold flag) but
-- is a separate table owned by the individual service. Confirm which one your
-- deployment actually writes to before capturing it -- one of the two may be
-- dormant.
CREATE TABLE household_individual
(
    individualid                character varying(64),
    individualclientreferenceid character varying(64),
    householdid                 character varying(64),
    householdclientreferenceid  character varying(64),
    isheadofhousehold           boolean,
    createdby                   character varying(64),
    lastmodifiedby              character varying(64),
    createdtime                 bigint,
    lastmodifiedtime            bigint,
    rowversion                  bigint,
    isdeleted                   boolean
);

CREATE TABLE STOCK
(
    id                     character varying(64),
    clientReferenceId      character varying(64),
    tenantId               character varying(1000),
    facilityId             character varying(64),
    productVariantId       character varying(64),
    quantity               bigint,
    waybillNumber          character varying(200),
    dateOfEntry            bigint,
    campaignNumber         character varying(64),
    referenceId            character varying(200),
    referenceIdType        character varying(100),
    transactionType        character varying(100),
    transactionReason      character varying(100),
    transactingPartyId     character varying(64),
    transactingPartyType   character varying(100),
    senderType             character varying(128),
    senderId               character varying(128),
    receiverType           character varying(128),
    receiverId             character varying(128),
    additionalDetails      jsonb,
    createdBy              character varying(64),
    createdTime            bigint,
    lastModifiedBy         character varying(64),
    lastModifiedTime       bigint,
    clientCreatedTime      bigint,
    clientLastModifiedTime bigint,
    clientCreatedBy        character varying(64),
    clientLastModifiedBy   character varying(64),
    rowVersion             bigint,
    isDeleted              boolean,
    CONSTRAINT uk_stock_id PRIMARY KEY (id),
    CONSTRAINT uk_stock_clientReferenceId UNIQUE (clientReferenceId)
);

CREATE INDEX idx_stock_clientReferenceId ON STOCK (clientReferenceId);
CREATE INDEX idx_stock_facilityId ON STOCK (facilityId);
CREATE INDEX idx_stock_productVariantId ON STOCK (productVariantId);
CREATE INDEX idx_stock_referenceId ON STOCK (referenceId);
CREATE INDEX idx_stock_wayBillNumber ON STOCK (wayBillNumber);
CREATE INDEX idx_stock_referenceIdType ON STOCK (referenceIdType);
CREATE INDEX idx_stock_transactionType ON STOCK (transactionType);
CREATE INDEX idx_stock_transactionReason ON STOCK (transactionReason);
CREATE INDEX idx_stock_transactingPartyId ON STOCK (transactingPartyId);
CREATE INDEX idx_stock_transactingPartyType ON STOCK (transactingPartyType);


CREATE TABLE STOCK_RECONCILIATION_LOG
(
    id                       character varying(64),
    clientReferenceId        character varying(64),
    tenantId                 character varying(1000),
    facilityId               character varying(64),
    productVariantId         character varying(64),
    dateOfReconciliation     bigint,
    calculatedCount          int,
    physicalRecordedCount    int,
    commentsOnReconciliation character varying(1000),
    referenceId              character varying(200),
    referenceIdType          character varying(100),
    additionalDetails        jsonb,
    createdBy                character varying(64),
    createdTime              bigint,
    lastModifiedBy           character varying(64),
    lastModifiedTime         bigint,
    clientCreatedTime        bigint,
    clientLastModifiedTime   bigint,
    clientCreatedBy          character varying(64),
    clientLastModifiedBy     character varying(64),
    rowVersion               bigint,
    isDeleted                boolean,
    CONSTRAINT uk_stock_reconciliation_id PRIMARY KEY (id),
    CONSTRAINT uk_stock_reconciliation_clientReferenceId UNIQUE (clientReferenceId)
);

CREATE INDEX idx_stock_recondiliation_clientReferenceId ON STOCK_RECONCILIATION_LOG (clientReferenceId);
CREATE INDEX idx_stock_recondiliation_facilityId ON STOCK_RECONCILIATION_LOG (facilityId);
CREATE INDEX idx_stock_recondiliation_productVariantId ON STOCK_RECONCILIATION_LOG (productVariantId);



CREATE TABLE FACILITY
(
    id                   character varying(64),
    tenantId             character varying(1000),
    isPermanent          boolean,
    name                 character varying(2000),
    usage                character varying(200),
    storageCapacity      bigint,
    addressId            character varying(64),
    additionalDetails    jsonb,
    createdBy            character varying(64),
    createdTime          bigint,
    lastModifiedBy       character varying(64),
    lastModifiedTime     bigint,
    rowVersion           bigint,
    isDeleted            boolean,
    clientreferenceid    character varying(64),
    CONSTRAINT pk_facility_id PRIMARY KEY (id)
);

CREATE TABLE PRODUCT
(
    id                character varying(64),
    tenantId          character varying(1000),
    type              character varying(200),
    name              character varying(1000),
    manufacturer      character varying(1000),
    additionalDetails text,
    createdBy         character varying(64),
    lastModifiedBy    character varying(64),
    createdTime       bigint,
    lastModifiedTime  bigint,
    rowVersion        bigint,
    isDeleted         boolean,
    CONSTRAINT uk_product_id PRIMARY KEY (id)
);

CREATE TABLE PRODUCT_VARIANT
(
    id                character varying(64),
    tenantId          character varying(1000),
    productId         character varying(64),
    sku               character varying(1000),
    variation         character varying(1000),
    additionalDetails jsonb,
    createdBy         character varying(64),
    lastModifiedBy    character varying(64),
    createdTime       bigint,
    lastModifiedTime  bigint,
    rowVersion        bigint,
    isDeleted         boolean,
    CONSTRAINT uk_product_variant_id PRIMARY KEY (id)
);


CREATE TABLE eg_service(
    id character varying(64),
    tenantId character varying(64),
    serviceDefId character varying(64),
    referenceId character varying(64),
    createdBy character varying(64),
    lastModifiedBy character varying(64),
    createdTime bigint,
    lastModifiedTime bigint,
    additionalDetails JSONB,
    accountId character varying(64),
    clientId character varying(64),
    CONSTRAINT uk_eg_service UNIQUE (id)
);

CREATE TABLE eg_service_attribute_value(
    id character varying(64),
    referenceId character varying(64),
    attributeCode character varying(64),
    "value" JSONB,
    createdBy character varying(64),
    lastModifiedBy character varying(64),
    createdTime bigint,
    lastModifiedTime bigint,
    additionalDetails JSONB,
    serviceClientReferenceId  character varying(64),
    CONSTRAINT uk_eg_attribute_value UNIQUE (id)
);

CREATE TABLE eg_pgr_service_v2(
    id                  character varying(64),
    tenantId            character varying(256),
    serviceCode         character varying(256)  NOT NULL,
    serviceRequestId    character varying(256),
    description         character varying(4000) NOT NULL,
    accountId           character varying(256),
    additionalDetails   JSONB,
    applicationStatus   character varying(128),
    rating              smallint,
    source              character varying(256),
    createdby           character varying(256)  NOT NULL,
    createdtime         bigint                  NOT NULL,
    lastmodifiedby      character varying(256),
    lastmodifiedtime    bigint,
    active              BOOLEAN DEFAULT TRUE,
    selfComplaint       boolean,
    hierarchytype       character varying(64),
    CONSTRAINT uk_eg_pgr_service_v2 UNIQUE (id),
    CONSTRAINT pk_eg_pgr_serviceReq_v2 PRIMARY KEY (tenantId,serviceRequestId)
);


CREATE TABLE eg_pgr_address_v2 (

tenantId          CHARACTER VARYING(256)  NOT NULL,
id                CHARACTER VARYING(256)  NOT NULL,
parentid         	CHARACTER VARYING(256)  NOT NULL,
doorno            CHARACTER VARYING(128),
plotno            CHARACTER VARYING(256),
buildingName     	CHARACTER VARYING(1024),
street           	CHARACTER VARYING(1024),
landmark         	CHARACTER VARYING(1024),
city             	CHARACTER VARYING(512),
pincode          	CHARACTER VARYING(16),
locality         	CHARACTER VARYING(128)  NOT NULL,
district          CHARACTER VARYING(256),
region            CHARACTER VARYING(256),
state             CHARACTER VARYING(256),
country           CHARACTER VARYING(512),
latitude         	NUMERIC(9,6),
longitude        	NUMERIC(10,7),
createdby        	CHARACTER VARYING(128)  NOT NULL,
createdtime      	BIGINT NOT NULL,
lastmodifiedby   	CHARACTER VARYING(128),
lastmodifiedtime 	BIGINT,
additionaldetails JSONB,

CONSTRAINT pk_eg_pgr_address_v2 PRIMARY KEY (id),
CONSTRAINT fk_eg_pgr_address_v2 FOREIGN KEY (parentid) REFERENCES eg_pgr_service_v2 (id)
);
CREATE INDEX IF NOT EXISTS index_eg_pgr_address_v2_locality ON eg_pgr_address_v2 (locality);


CREATE TABLE eg_wms_attendance_register (                                                                                                                                  
      id                     character varying(256),                                                                                                                         
      tenantid               character varying(64)  NOT NULL,                                                                                                                
      registernumber         character varying(256) NOT NULL,                                                                                                                
      name                   character varying(256),                                                                                                                         
      startdate              bigint NOT NULL,                                                                                                                                
      enddate                bigint,                                                                                                                                         
      status                 character varying(64)  NOT NULL,                                                                                                                
      additionaldetails      JSONB,                                                                                                                                          
      createdby              character varying(256) NOT NULL,                                                                                                                
      lastmodifiedby         character varying(256),                                                                                                                         
      createdtime            bigint,                                                                                                                                         
      lastmodifiedtime       bigint,                                                                                                                                         
      referenceid            character varying(256),                                                                                                                         
      servicecode            character varying(64),                                                                                                                          
      localitycode           character varying(256),                                                                                                                         
      reviewstatus           character varying(64),                                                                                                                          
      period_statuses        JSONB DEFAULT '[]'::jsonb,                                                                                                                      
      campaignnumber         character varying(256),                                                                                                                         
      isdeleted              boolean DEFAULT false,                                                                                                                          
      CONSTRAINT pk_eg_wms_attendance_register PRIMARY KEY (id),                                                                                                             
      CONSTRAINT uk_eg_wms_attendance_register UNIQUE (registernumber)                                                                                                       
  );      

CREATE TABLE eg_wms_attendance_staff (                                                                                                                                     
      id                     character varying(256),                                                                                                                         
      individual_id          character varying(256) NOT NULL,                                                                                                                
      register_id            character varying(256) NOT NULL,                                                                                                                
      tenantid               character varying(64),                                                                                                                          
      enrollment_date        bigint NOT NULL,                                                                                                                                
      deenrollment_date      bigint,                                                                                                                                         
      additionaldetails      JSONB,                                                                                                                                          
      createdby              character varying(256) NOT NULL,                                                                                                                
      lastmodifiedby         character varying(256),                                                                                                                         
      createdtime            bigint,                                                                                                                                         
      lastmodifiedtime       bigint,                                                                                                                                         
      stafftype              character varying(64),                                                                                                                          
      CONSTRAINT pk_eg_wms_attendance_staff PRIMARY KEY (id),                                                                                                                
      CONSTRAINT fk_eg_wms_attendance_staff FOREIGN KEY (register_id)                                                                                                        
          REFERENCES eg_wms_attendance_register (id)                                                                                                                         
  );        


CREATE TABLE eg_wms_attendance_attendee (                                                                                                                                  
      id                     character varying(256),                                                                                                                         
      individual_id          character varying(256) NOT NULL,                                                                                                                
      register_id            character varying(256) NOT NULL,                                                                                                                
      enrollment_date        bigint NOT NULL,                                                                                                                                
      deenrollment_date      bigint,                                                                                                                                         
      additionaldetails      JSONB,                                                                                                                                          
      createdby              character varying(256) NOT NULL,                                                                                                                
      lastmodifiedby         character varying(256),                                                                                                                         
      createdtime            bigint,                                                                                                                                         
      lastmodifiedtime       bigint,                                                                                                                                         
      tenantid               character varying(64),                                                                                                                          
      tag                    character varying(64),                                                                                                                          
      CONSTRAINT pk_eg_wms_attendance_attendee PRIMARY KEY (id),                                                                                                             
      CONSTRAINT fk_eg_wms_attendance_attendee FOREIGN KEY (register_id)                                                                                                     
          REFERENCES eg_wms_attendance_register (id)                                                                                                                         
  );         


CREATE TABLE eg_wms_attendance_log (                                                                                                                                       
      id                     character varying(256),                                                                                                                         
      individual_id          character varying(256) NOT NULL,                                                                                                                
      register_id            character varying(256) NOT NULL,                                                                                                                
      status                 character varying(64),                                                                                                                          
      time                   bigint NOT NULL,                                                                                                                                
      event_type             character varying(64),                                                                                                                          
      additionaldetails      JSONB,                                                                                                                                          
      createdby              character varying(256) NOT NULL,                                                                                                                
      lastmodifiedby         character varying(256),                                                                                                                         
      createdtime            bigint,                                                                                                                                         
      lastmodifiedtime       bigint,                                                                                                                                         
      tenantid               character varying(64),                                                                                                                          
      clientreferenceid      character varying(256),                                                                                                                         
      clientcreatedby        character varying(256),                                                                                                                         
      clientlastmodifiedby   character varying(256),                                                                                                                         
      clientcreatedtime      bigint,                                                                                                                                         
      clientlastmodifiedtime bigint,                                                                                                                                         
      CONSTRAINT pk_eg_wms_attendance_log PRIMARY KEY (id),                                                                                                                  
      CONSTRAINT fk_eg_wms_attendance_log FOREIGN KEY (register_id)                                                                                                          
          REFERENCES eg_wms_attendance_register (id)                                                                                                                         
  );          

CREATE TABLE eg_wms_attendance_document (                                                                                                                                  
      id                     character varying(256),                                                                                                                         
      filestore_id           character varying(256) NOT NULL,                                                                                                                
      document_type          character varying(256),                                                                                                                         
      attendance_log_id      character varying(256) NOT NULL,                                                                                                                
      additionaldetails      JSONB,                                                                                                                                          
      createdby              character varying(256) NOT NULL,                                                                                                                
      lastmodifiedby         character varying(256),                                                                                                                         
      createdtime            bigint,                                                                                                                                         
      lastmodifiedtime       bigint,                                                                                                                                         
      tenantid               character varying(64),                                                                                                                          
      status                 character varying(64),                                                                                                                          
      CONSTRAINT pk_eg_wms_attendance_document PRIMARY KEY (id),                                                                                                             
      CONSTRAINT fk_eg_wms_attendance_document FOREIGN KEY (attendance_log_id)                                                                                               
          REFERENCES eg_wms_attendance_log (id)                                                                                                                              
  );

CREATE TABLE eg_wms_face_auth_event (                                                                                                                                      
      id                     VARCHAR(256) NOT NULL,                                                                                                                          
      clientreferenceid      VARCHAR(256),                                                                                                                                   
      tenantid               VARCHAR(256) NOT NULL,                                                                                                                          
      individual_id          VARCHAR(256) NOT NULL,                                                                                                                          
      device_id              VARCHAR(256),                                                                                                                                   
      event_type             VARCHAR(64)  NOT NULL,                                                                                                                          
      outcome                VARCHAR(64)  NOT NULL,                                                                                                                          
      confidence             NUMERIC(5,4),                                                                                                                                   
      latitude               NUMERIC(10,7),                                                                                                                                  
      longitude              NUMERIC(10,7),                                                                                                                                  
      location_accuracy      NUMERIC(10,3),                                                                                                                                  
      event_timestamp        NUMERIC(20,0),                                                                                                                                  
      failed_attempt_count   INTEGER DEFAULT 0,                                                                                                                              
      popup_time             NUMERIC(20,0),                                                                                                                                  
      response_time          NUMERIC(20,0),                                                                                                                                  
      response_type          VARCHAR(64),                                                                                                                                    
      face_image             TEXT,                                                                                                                                           
      anomaly_flags          VARCHAR(512),                                                                                                                                   
      project_id             VARCHAR(256),                                                                                                                                   
      boundary_code          VARCHAR(256),                                                                                                                                   
      additionaldetails      JSONB,                 
          createdby              VARCHAR(256) NOT NULL,                                                                                                                          
      lastmodifiedby         VARCHAR(256),                                                                                                                                   
      createdtime            BIGINT NOT NULL,                                                                                                                                
      lastmodifiedtime       BIGINT,                                                                                                                                         
      clientcreatedby        VARCHAR(256),                                                                                                                                   
      clientlastmodifiedby   VARCHAR(256),                                                                                                                                   
      clientcreatedtime      BIGINT,                                                                                                                                         
      clientlastmodifiedtime BIGINT,                                                                                                                                         
      CONSTRAINT pk_eg_wms_face_auth_event PRIMARY KEY (id)                                                                                                                  
  );     


Indexes                                                                                                                                                                    
                                                                                                                                                                             
  CREATE INDEX index_eg_wms_attendance_register_tenantid        ON eg_wms_attendance_register (tenantid);                                                                    
  CREATE INDEX index_eg_wms_attendance_register_id              ON eg_wms_attendance_register (id);                                                                          
  CREATE INDEX index_eg_wms_attendance_register_registernumber  ON eg_wms_attendance_register (registernumber);                                                              
  CREATE INDEX index_eg_wms_attendance_register_name            ON eg_wms_attendance_register (name);                                                                        
  CREATE INDEX index_eg_wms_attendance_register_startdate       ON eg_wms_attendance_register (startdate);                                                                   
  CREATE INDEX index_eg_wms_attendance_register_enddate         ON eg_wms_attendance_register (enddate);                                                                     
  CREATE INDEX index_eg_wms_attendance_register_status          ON eg_wms_attendance_register (status);                                                                      
  CREATE INDEX index_eg_wms_attendance_register_createdtime     ON eg_wms_attendance_register (createdtime);                                                                 
  CREATE INDEX index_eg_wms_attendance_register_reference_id    ON eg_wms_attendance_register (referenceid);                                                                 
  CREATE INDEX index_eg_wms_attendance_register_service_code    ON eg_wms_attendance_register (servicecode);                                                                 
  CREATE INDEX index_eg_wms_attendance_register_campaignnumber  ON eg_wms_attendance_register (campaignnumber);                                                              
  CREATE INDEX idx_attendance_register_period_statuses          ON eg_wms_attendance_register USING GIN (period_statuses);                                                   
                                                                                                                                                                             
  CREATE INDEX index_eg_wms_attendance_attendee_tag             ON eg_wms_attendance_attendee (tag);                                                                         
 
 CREATE INDEX index_eg_wms_attendance_log_tenantid             ON eg_wms_attendance_log (tenantid);                                                                         
  CREATE INDEX index_eg_wms_attendance_log_register_id          ON eg_wms_attendance_log (register_id);                                                                      
  CREATE INDEX index_eg_wms_attendance_log_time                 ON eg_wms_attendance_log (time);                                                                             
  CREATE INDEX index_eg_wms_attendance_log_individual_id        ON eg_wms_attendance_log (individual_id);                                                                    
  CREATE INDEX index_eg_wms_attendance_log_status               ON eg_wms_attendance_log (status);                                                                           
  CREATE INDEX index_eg_wms_attendance_log_createdtime          ON eg_wms_attendance_log (createdtime);                                                                      
                                                                                                                                                                             
  CREATE INDEX idx_face_auth_event_individual_id                ON eg_wms_face_auth_event (individual_id);                                                                   
  CREATE INDEX idx_face_auth_event_tenantid                     ON eg_wms_face_auth_event (tenantid);                                                                        
  CREATE INDEX idx_face_auth_event_event_type                   ON eg_wms_face_auth_event (event_type);                                                                      
  CREATE INDEX idx_face_auth_event_outcome                      ON eg_wms_face_auth_event (outcome);                                                                         
  CREATE INDEX idx_face_auth_event_timestamp                    ON eg_wms_face_auth_event (event_timestamp);                                                                 
  CREATE INDEX idx_face_auth_event_clientrefid                  ON eg_wms_face_auth_event (clientreferenceid);                                                               
  CREATE INDEX idx_face_auth_event_project_id                   ON eg_wms_face_auth_event (project_id);                                                                      
    

CREATE TABLE eg_expense_bill (                                                                                                                                             
      id                VARCHAR(64)  NOT NULL,                                                                                                                               
      tenantid          VARCHAR(250) NOT NULL,                                                                                                                               
      billdate          BIGINT       NOT NULL,                                                                                                                               
      duedate           BIGINT,                                                                                                                                              
      totalamount       NUMERIC(12,2),                                                                                                                                       
      totalpaidamount   NUMERIC(12,2),                                                                                                                                       
      businessservice   VARCHAR(250) NOT NULL,                                                                                                                               
      referenceid       VARCHAR(250) NOT NULL,   -- entity the bill is generated for                                                                                         
      fromperiod        BIGINT,                                                                                                                                              
      toperiod          BIGINT,                                                                                                                                              
      status            VARCHAR(64)  NOT NULL,                                                                                                                               
      paymentstatus     VARCHAR(64),                                                                                                                                         
      billnumber        VARCHAR(128) NOT NULL,                                                                                                                               
      localitycode      VARCHAR(256),            -- added V20250102140140                                                                                                    
      createdby         VARCHAR(64)  NOT NULL,                                                                                                                               
      createdtime       BIGINT       NOT NULL,                                                                                                                               
      lastmodifiedby    VARCHAR(64)  NOT NULL,                                                                                                                               
      lastmodifiedtime  BIGINT       NOT NULL,                                                                                                                               
      additionaldetails JSONB,                                                                                                                                               
                                                                                                                                                                             
      CONSTRAINT pk_eg_expense_bill PRIMARY KEY (id, tenantid)                                                                                                               
  );      \
 -- V20251114150000 replaced the v1 3-column index with this period-aware one                                                                                               
  CREATE UNIQUE INDEX index_unique_eg_expense_bill                                                                                                                           
      ON eg_expense_bill (referenceid, businessservice, tenantid, fromperiod, toperiod)                                                                                      
      WHERE status != 'INACTIVE';                                                                                                                                            
                                                                                                                                                                             
  -- V20251204120000: partial expression indexes on V2 JSONB fields                                                                                                          
  CREATE INDEX idx_expense_bill_billing_period_id ON eg_expense_bill ((additionaldetails->>'billingPeriodId'))                                                               
      WHERE additionaldetails->>'billingPeriodId' IS NOT NULL;                                                                                                               
  CREATE INDEX idx_expense_bill_billing_type      ON eg_expense_bill ((additionaldetails->>'billingType'))                                                                   
      WHERE additionaldetails->>'billingType' IS NOT NULL;                                                                                                                   
  CREATE INDEX idx_expense_bill_is_aggregate      ON eg_expense_bill ((additionaldetails->>'isAggregate'))                                                                   
      WHERE additionaldetails->>'isAggregate' IS NOT NULL;                                                                                                                   
  CREATE INDEX idx_expense_bill_report_status     ON eg_expense_bill ((additionaldetails->'reportDetails'->>'status'))                                                       
      WHERE additionaldetails->'reportDetails'->>'status' IS NOT NULL;


 CREATE TABLE eg_expense_party (                                                                                                                                            
      id                VARCHAR(64)  NOT NULL,                                                                                                                               
      tenantid          VARCHAR(250) NOT NULL,                                                                                                                               
      type              VARCHAR(250) NOT NULL,                                                                                                                               
      status            VARCHAR(64)  NOT NULL,                                                                                                                               
      identifier        VARCHAR(250) NOT NULL,                                                                                                                               
      parentid          VARCHAR(250) NOT NULL,   -- bill.id when payer, billdetail.id when payee                                                                             
      -- added V20260415120000                                                                                                                                               
      paymentprovider   VARCHAR(16),                                                                                                                                         
      payeename         VARCHAR(256),                                                                                                                                        
      payeephonenumber  VARCHAR(64),                                                                                                                                         
      bankaccount       VARCHAR(128),                                                                                                                                        
      bankcode          VARCHAR(64),                                                                                                                                         
      beneficiarycode   VARCHAR(128),                                                                                                                                        
      createdby         VARCHAR(64)  NOT NULL,                                                                                                                               
      createdtime       BIGINT       NOT NULL,                                                                                                                               
      lastmodifiedby    VARCHAR(64)  NOT NULL,                                                                                                                               
      lastmodifiedtime  BIGINT       NOT NULL,                                                                                                                               
      additionaldetails JSONB,                                                                                                                                               
                                                                                                                                                                             
      CONSTRAINT pk_eg_expense_party PRIMARY KEY (id, tenantid)                                                                                                              
  );             


CREATE TABLE eg_expense_billdetail (                                                                                                                                       
      id                 VARCHAR(64)  NOT NULL,                                                                                                                              
      tenantid           VARCHAR(250) NOT NULL,                                                                                                                              
      referenceid        VARCHAR(250),                                                                                                                                       
      billid             VARCHAR(64)  NOT NULL,                                                                                                                              
      totalamount        NUMERIC(12,2),                                                                                                                                      
      totalpaidamount    NUMERIC(12,2),                                                                                                                                      
      paymentstatus      VARCHAR(64),                                                                                                                                        
      status             VARCHAR(64)  NOT NULL,                                                                                                                              
      fromperiod         BIGINT,                                                                                                                                             
      toperiod           BIGINT,                                                                                                                                             
      netlineitemamount  NUMERIC(12,2),                                                                                                                                      
      totalattendance    NUMERIC,                 -- added V20260414120000                                                                                                   
      workerid           VARCHAR(64),             -- added V20260415120000                                                                                                   
      createdby          VARCHAR(64)  NOT NULL,                                                                                                                              
      createdtime        BIGINT       NOT NULL,                                                                                                                              
      lastmodifiedby     VARCHAR(64)  NOT NULL,                                                                                                                              
      lastmodifiedtime   BIGINT       NOT NULL,                                                                                                                              
      additionaldetails  JSONB,                                                                                                                                              
                                                                                                                                                                             
      CONSTRAINT pk_eg_expense_billdetail PRIMARY KEY (id, tenantid),                                                                                                        
      CONSTRAINT fk_eg_expense_billdetail FOREIGN KEY (billid, tenantid)                                                                                                     
          REFERENCES eg_expense_bill (id, tenantid)                                                                                                                          
  );          


CREATE TABLE eg_expense_lineitem (                                                                                                                                         
      id                VARCHAR(64)   NOT NULL,                                                                                                                              
      billdetailid      VARCHAR(64)   NOT NULL,                                                                                                                              
      tenantid          VARCHAR(250)  NOT NULL,                                                                                                                              
      headcode          VARCHAR(250)  NOT NULL,                                                                                                                              
      amount            NUMERIC(12,2) NOT NULL,                                                                                                                              
      paidamount        NUMERIC(12,2) NOT NULL,                                                                                                                              
      type              VARCHAR(64)   NOT NULL,   -- PAYABLE | DEDUCTION                                                                                                     
      status            VARCHAR(64)   NOT NULL,                                                                                                                              
      paymentstatus     VARCHAR(64),                                                                                                                                         
      islineitempayable BOOLEAN       NOT NULL,   -- splits lineItems vs payableLineItems                                                                                    
      createdby         VARCHAR(64)   NOT NULL,                                                                                                                              
      createdtime       BIGINT        NOT NULL,                                                                                                                              
      lastmodifiedby    VARCHAR(64)   NOT NULL,                                                                                                                              
      lastmodifiedtime  BIGINT        NOT NULL,                                                                                                                              
      additionaldetails JSONB,                                                                                                                                               
                                                                                                                                                                             
      CONSTRAINT pk_eg_expense_lineitem PRIMARY KEY (id, tenantid),                                                                                                          
      CONSTRAINT fk_eg_expense_lineitem FOREIGN KEY (billdetailid, tenantid)                                                                                                 
          REFERENCES eg_expense_billdetail (id, tenantid)                                                                                                                    
  );   

 CREATE TABLE referral
  (
      id                                  character varying(64),
      clientReferenceId                   character varying(64),
      tenantId                            character varying(1000),
      projectBeneficiaryId                character varying(64),
      projectBeneficiaryClientReferenceId character varying(64),
      referrerId                          character varying(100),
      recipientId                         character varying(100),
      recipientType                       character varying(100),
      reasons                             jsonb,
      sideEffectId                        character varying(100),
      sideEffectClientReferenceId         character varying(100),
      createdBy                           character varying(64),
      createdTime                         bigint,
      lastModifiedBy                      character varying(64),
      lastModifiedTime                    bigint,
      clientCreatedBy                     character varying(64),
      clientCreatedTime                   bigint,
      clientLastModifiedBy                character varying(64),
      clientLastModifiedTime              bigint,
      rowVersion                          bigint,
      isDeleted                           boolean,
      additionalDetails                   jsonb,
      referralCode                        character varying(256),
      projectId                           character varying(64),
      CONSTRAINT uk_referral_id PRIMARY KEY (id),
      CONSTRAINT uk_referral_clientReferenceId UNIQUE (clientReferenceId)
  );

  CREATE INDEX idx_referral_projectid ON referral(projectid);


  CREATE TABLE side_effect
  (
      id                                  character varying(64),
      clientReferenceId                   character varying(64) NOT NULL,
      tenantId                            character varying(1000),
      taskId                              character varying(64),
      taskClientReferenceId               character varying(64) NOT NULL,
      projectBeneficiaryId                character varying(64),
      projectBeneficiaryClientReferenceId character varying(64),
      symptoms                            jsonb,
      createdBy                           character varying(64),
      createdTime                         bigint,
      lastModifiedBy                      character varying(64),
      lastModifiedTime                    bigint,
      clientCreatedBy                     character varying(64),
      clientCreatedTime                   bigint,
      clientLastModifiedBy                character varying(64),
      clientLastModifiedTime              bigint,
      rowVersion                          bigint,
      isDeleted                           boolean,
      additionalDetails                   jsonb,
      CONSTRAINT uk_side_effect PRIMARY KEY (id),
      CONSTRAINT uk_side_effect_clientReference_id UNIQUE (clientReferenceId)
  );

  CREATE TABLE hf_referral
  (
      id                     character varying(64),
      clientreferenceid      character varying(64),
      tenantid               character varying(1000),
      projectid              character varying(64),
      projectfacilityid      character varying(64),
      symptom                character varying(256),
      symptomsurveyid        character varying(100),
      beneficiaryid          character varying(100),
      referralcode           character varying(100),
      nationallevelid        character varying(100),
      createdby              character varying(64),
      createdtime            bigint,
      lastmodifiedby         character varying(64),
      lastmodifiedtime       bigint,
      clientcreatedby        character varying(64),
      clientcreatedtime      bigint,
      clientlastmodifiedby   character varying(64),
      clientlastmodifiedtime bigint,
      rowversion             bigint,
      isdeleted              boolean,
      additionaldetails      jsonb,
      localitycode           character varying(100),
      CONSTRAINT uk_hf_referral_id PRIMARY KEY (id),
      CONSTRAINT uk_hf_referral_clientReferenceId UNIQUE (clientReferenceId)
  );

  CREATE INDEX idx_hf_referral_projectfacilityid ON hf_referral(projectfacilityid);
  CREATE INDEX idx_hf_referral_tenantid          ON hf_referral(tenantid);
  CREATE INDEX idx_hf_referral_localitycode      ON hf_referral(localitycode);


  CREATE TABLE eg_service_definition
  (
      id                character varying(64),
      tenantId          character varying(64),
      code              character varying(256),
      isActive          boolean,
      createdBy         character varying(64),
      lastModifiedBy    character varying(64),
      createdTime       bigint,
      lastModifiedTime  bigint,
      additionalDetails jsonb,
      clientId          character varying(64),
      CONSTRAINT uk_eg_service_definition UNIQUE (id),
      CONSTRAINT pk_eg_service_definition PRIMARY KEY (tenantId, code)
  );


  CREATE TABLE eg_wms_muster_roll
  (
      id                     character varying(256),
      tenant_id              character varying(64)  NOT NULL,
      musterroll_number      character varying(128) NOT NULL,
      attendance_register_id character varying(256) NOT NULL,
      start_date             bigint                NOT NULL,
      end_date               bigint                NOT NULL,
      musterroll_status      character varying(64)  NOT NULL,
      status                 character varying(64)  NOT NULL,
      additionaldetails      jsonb,
      createdby              character varying(256) NOT NULL,
      lastmodifiedby         character varying(256),
      createdtime            bigint,
      lastmodifiedtime       bigint,
      reference_id           character varying(256),
      service_code           character varying(64),
      billing_period_id      character varying(64),
      CONSTRAINT pk_eg_wms_muster_roll PRIMARY KEY (id),
      CONSTRAINT uk_eg_wms_muster_roll UNIQUE (musterroll_number)
  );

  CREATE INDEX index_eg_wms_muster_roll_id                   ON eg_wms_muster_roll (id);
  CREATE INDEX index_eg_wms_muster_roll_tenantId             ON eg_wms_muster_roll (tenant_id);
  CREATE INDEX index_eg_wms_muster_roll_musterRollNumber     ON eg_wms_muster_roll (musterroll_number);
  CREATE INDEX index_eg_wms_muster_roll_attendanceRegisterId ON eg_wms_muster_roll (attendance_register_id);
  CREATE INDEX index_eg_wms_muster_roll_status               ON eg_wms_muster_roll (status);
  CREATE INDEX index_eg_wms_muster_roll_musterRollStatus     ON eg_wms_muster_roll (musterroll_status);
  CREATE INDEX index_eg_wms_muster_roll_startDate            ON eg_wms_muster_roll (start_date);
  CREATE INDEX index_eg_wms_muster_roll_endDate              ON eg_wms_muster_roll (end_date);
  CREATE INDEX index_eg_wms_muster_roll_createdtime          ON eg_wms_muster_roll (createdtime);
  CREATE INDEX index_eg_wms_muster_roll_reference_id         ON eg_wms_muster_roll (reference_id);
  CREATE INDEX index_eg_wms_muster_roll_service_code         ON eg_wms_muster_roll (service_code);
  CREATE INDEX idx_muster_roll_period                        ON eg_wms_muster_roll (billing_period_id);
  CREATE INDEX idx_muster_roll_register_period               ON eg_wms_muster_roll (attendance_register_id, billing_period_id);
  CREATE INDEX idx_muster_roll_period_tenant                 ON eg_wms_muster_roll (billing_period_id, tenant_id);

  CREATE UNIQUE INDEX uk_muster_register_period
      ON eg_wms_muster_roll (attendance_register_id, billing_period_id, tenant_id)
      WHERE billing_period_id IS NOT NULL;

  CREATE INDEX idx_muster_roll_period_status
      ON eg_wms_muster_roll (billing_period_id, musterroll_status, tenant_id)
      WHERE billing_period_id IS NOT NULL;


  CREATE TABLE eg_wms_attendance_summary
  (
      id                        character varying(256),
      individual_id             character varying(256) NOT NULL,
      muster_roll_id            character varying(256) NOT NULL,
      musterroll_number         character varying(128) NOT NULL,
      actual_total_attendance   numeric,
      modified_total_attendance numeric,
      additionaldetails         jsonb,
      createdby                 character varying(256) NOT NULL,
      lastmodifiedby            character varying(256),
      createdtime               bigint,
      lastmodifiedtime          bigint,
      billing_period_id         character varying(64),
      total_registrations       bigint DEFAULT 0,
      total_interventions       bigint DEFAULT 0,
      tag                       character varying(256),
      role                      character varying(128),
      CONSTRAINT pk_eg_wms_attendance_summary PRIMARY KEY (id),
      CONSTRAINT fk_eg_wms_attendance_summary FOREIGN KEY (muster_roll_id) REFERENCES eg_wms_muster_roll (id)
  );

  CREATE INDEX index_eg_wms_attendance_summary_id                        ON eg_wms_attendance_summary (id);
  CREATE INDEX index_eg_wms_attendance_summary_musterRollNumber          ON eg_wms_attendance_summary (musterroll_number);
  CREATE INDEX index_eg_wms_attendance_summary_individual_id             ON eg_wms_attendance_summary (individual_id);
  CREATE INDEX index_eg_wms_attendance_summary_createdtime               ON eg_wms_attendance_summary (createdtime);
  CREATE INDEX index_eg_wms_attendance_summary_actual_total_attendance   ON eg_wms_attendance_summary (actual_total_attendance);
  CREATE INDEX index_eg_wms_attendance_summary_modified_total_attendance ON eg_wms_attendance_summary (modified_total_attendance);

  CREATE UNIQUE INDEX uk_attendance_summary_individual_muster_period
      ON eg_wms_attendance_summary (individual_id, muster_roll_id, billing_period_id)
      WHERE billing_period_id IS NOT NULL;

  CREATE INDEX idx_attendance_summary_period
      ON eg_wms_attendance_summary (billing_period_id)
      WHERE billing_period_id IS NOT NULL;

  CREATE INDEX idx_attendance_summary_period_individual
      ON eg_wms_attendance_summary (billing_period_id, individual_id)
      WHERE billing_period_id IS NOT NULL;
