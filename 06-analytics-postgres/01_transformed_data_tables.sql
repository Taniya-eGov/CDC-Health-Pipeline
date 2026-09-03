CREATE TABLE IF NOT EXISTS household_enriched (
    -- Household core fields
    id                              VARCHAR(64)         PRIMARY KEY,
    tenant_id                       VARCHAR(1000)       NOT NULL,
    client_reference_id             VARCHAR(64),
    member_count                    INTEGER             NOT NULL,
    is_deleted                      BOOLEAN,
    row_version                     INTEGER,

    -- Household.address (flattened)
    address_id                      VARCHAR(64),
    address_latitude                DOUBLE PRECISION,
    address_longitude               DOUBLE PRECISION,
    address_location_accuracy       DOUBLE PRECISION,
    address_type                    VARCHAR(64),
    address_locality                JSONB,

    -- Household.additionalFields
    household_additional_fields     JSONB,

    -- Household.auditDetails
    created_by                      VARCHAR(64),
    last_modified_by                VARCHAR(64),
    created_time                    BIGINT,
    last_modified_time              BIGINT,

    -- Household.clientAuditDetails
    client_created_by               VARCHAR(64),
    client_last_modified_by         VARCHAR(64),
    client_created_time             BIGINT,
    client_last_modified_time       BIGINT,

    -- HouseholdIndexV1 top-level fields
    user_name                       VARCHAR(180),
    name_of_user                    VARCHAR(250),
    user_address                    VARCHAR(440),
    task_dates                      DATE,
    synced_date                     DATE,
    role                            VARCHAR(128),
    boundary_hierarchy              JSONB,
    boundary_hierarchy_code         JSONB,
    geo_point_lat                   DOUBLE PRECISION,
    geo_point_lon                   DOUBLE PRECISION,
    synced_time_stamp               TIMESTAMPTZ,
    synced_time                     BIGINT,
    additional_details              JSONB
);

CREATE TABLE IF NOT EXISTS household_member_enriched (
    -- HouseholdMember core fields
    id                                      VARCHAR(64)     PRIMARY KEY,
    tenant_id                               VARCHAR(1000)   NOT NULL,
    client_reference_id                     VARCHAR(64)     NOT NULL,
    household_id                            VARCHAR(64),
    household_client_reference_id           VARCHAR(64),
    individual_id                           VARCHAR(64),
    individual_client_reference_id          VARCHAR(64),
    is_head_of_household                    BOOLEAN,
    is_deleted                              BOOLEAN,
    row_version                             INTEGER,

    -- HouseholdMember.additionalFields
    member_additional_fields                JSONB,

    -- HouseholdMember.auditDetails
    created_by                              VARCHAR(64),
    last_modified_by                        VARCHAR(64),
    created_time                            BIGINT,
    last_modified_time                      BIGINT,

    -- HouseholdMember.clientAuditDetails
    client_created_by                       VARCHAR(64),
    client_last_modified_by                 VARCHAR(64),
    client_created_time                     BIGINT,
    client_last_modified_time               BIGINT,

    -- HouseholdMemberIndexV1 top-level fields
    boundary_hierarchy                      JSONB,
    boundary_hierarchy_code                 JSONB,
    date_of_birth                           BIGINT,
    age                                     INTEGER,
    gender                                  VARCHAR(64),
    user_name                               VARCHAR(180),
    name_of_user                            VARCHAR(250),
    role                                    VARCHAR(128),
    user_address                            VARCHAR(440),
    task_dates                              DATE,
    synced_date                             DATE,
    synced_time_stamp                       TIMESTAMPTZ,
    geo_point_lat                           DOUBLE PRECISION,
    geo_point_lon                           DOUBLE PRECISION,
    locality_code                           VARCHAR(128),
    additional_details                      JSONB
);

CREATE TABLE IF NOT EXISTS project_beneficiary_enriched (
    -- ProjectBeneficiary core fields
    id                                      VARCHAR(64)     PRIMARY KEY,
    tenant_id                               VARCHAR(64)     NOT NULL,
    project_id                              VARCHAR(64)     NOT NULL,
    beneficiary_id                          VARCHAR(64),
    beneficiary_client_reference_id         VARCHAR(64),
    client_reference_id                     VARCHAR(64),
    date_of_registration                    BIGINT,
    tag                                     VARCHAR(1000),
    is_deleted                              BOOLEAN,
    row_version                             INTEGER,

    -- ProjectBeneficiary.additionalFields
    beneficiary_additional_fields           JSONB,

    -- ProjectBeneficiary.auditDetails
    created_by                              VARCHAR(64),
    last_modified_by                        VARCHAR(64),
    created_time                            BIGINT,
    last_modified_time                      BIGINT,

    -- ProjectBeneficiary.clientAuditDetails
    client_created_by                       VARCHAR(64),
    client_last_modified_by                 VARCHAR(64),
    client_created_time                     BIGINT,
    client_last_modified_time               BIGINT,

    -- ProjectBeneficiaryIndexV1 top-level fields
    boundary_hierarchy                      JSONB,
    boundary_hierarchy_code                 JSONB,
    user_name                               VARCHAR(180),
    name_of_user                            VARCHAR(250),
    role                                    VARCHAR(128),
    user_address                            VARCHAR(440),
    task_dates                              DATE,
    synced_date                             DATE,
    synced_time_stamp                       TIMESTAMPTZ,
    additional_details                      JSONB
);

CREATE TABLE IF NOT EXISTS attendance_log_enriched (
    -- AttendanceLog core fields
    id                                      VARCHAR(256)     PRIMARY KEY,
    tenant_id                               VARCHAR(64),
    register_id                             VARCHAR(256),
    individual_id                           VARCHAR(256),
    log_user_name                           VARCHAR(180),
    time                                    BIGINT,
    type                                    VARCHAR(64),
    status                                  VARCHAR(64),
    log_additional_details                  JSONB,

    -- AttendanceLog.auditDetails
    created_by                              VARCHAR(64),
    last_modified_by                        VARCHAR(64),
    created_time                            BIGINT,
    last_modified_time                      BIGINT,

    -- AttendanceLogIndexV1 top-level fields
    given_name                              VARCHAR(250),
    family_name                             VARCHAR(250),
    attendee_given_name                     VARCHAR(200),
    attendee_family_name                    VARCHAR(200),
    attendee_other_names                    VARCHAR(200),
    user_name                               VARCHAR(180),
    name_of_user                            VARCHAR(250),
    role                                    VARCHAR(128),
    user_address                            VARCHAR(440),
    attendance_time                         TIMESTAMPTZ,
    register_service_code                   VARCHAR(128),
    register_name                           VARCHAR(256),
    register_number                         VARCHAR(256),
    boundary_hierarchy                      JSONB,
    boundary_hierarchy_code                 JSONB,
    additional_details                      JSONB
);

CREATE TABLE IF NOT EXISTS attendance_register_enriched (
    -- AttendanceRegister core fields
    id                                      VARCHAR(256)    PRIMARY KEY,
    tenant_id                               VARCHAR(64),
    register_number                         VARCHAR(256),
    name                                    VARCHAR(250),
    reference_id                            VARCHAR(64),
    service_code                            VARCHAR(128),
    start_date                              BIGINT,
    end_date                                BIGINT,
    status                                  VARCHAR(64),
    staff                                   JSONB, --TODO: should this be kept in a separate table?
    attendees                               JSONB, --TODO: should this be kept in a separate table?

    -- AttendanceRegister.additionalDetails
    register_additional_details             JSONB,

    -- AttendanceRegister.auditDetails
    created_by                              VARCHAR(64),
    last_modified_by                        VARCHAR(64),
    created_time                            BIGINT,
    last_modified_time                      BIGINT,

    -- AttendanceRegisterIndexV1 top-level fields
    attendees_info                          JSONB,
    transformer_time_stamp                  TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS pgr_complaints_enriched (
    -- Service core fields
    id                                      VARCHAR(64)     PRIMARY KEY,
    tenant_id                               VARCHAR(64)     NOT NULL,
    service_code                            VARCHAR(128)    NOT NULL,
    service_request_id                      VARCHAR(128),
    description                             TEXT,
    account_id                              VARCHAR(64),
    rating                                  INTEGER,
    application_status                      VARCHAR(128),
    source                                  VARCHAR(64)     NOT NULL,
    active                                  BOOLEAN,
    self_complaint                          BOOLEAN,
    service_additional_detail               JSONB,

    -- Service.user (complainant, flattened)
    complainant_id                          BIGINT,
    complainant_user_name                   VARCHAR(180),
    complainant_name                        VARCHAR(250),
    complainant_type                        VARCHAR(64),
    complainant_mobile_number               VARCHAR(20),
    complainant_email_id                    VARCHAR(250),
    complainant_tenant_id                   VARCHAR(64),
    complainant_uuid                        VARCHAR(64),
    complainant_active                      BOOLEAN,
    complainant_roles                       JSONB,

    -- Service.address (flattened)
    address_id                              VARCHAR(64),
    address_locality                        JSONB,
    address_addition_details                JSONB,
    address_geo_lat                         DOUBLE PRECISION,
    address_geo_lon                         DOUBLE PRECISION,
    address_geo_additional_details          JSONB,

    -- Service.auditDetails
    created_by                              VARCHAR(64),
    last_modified_by                        VARCHAR(64),
    created_time                            BIGINT,
    last_modified_time                      BIGINT,

    -- PGRIndex top-level fields
    user_name                               VARCHAR(180),
    name_of_user                            VARCHAR(250),
    role                                    VARCHAR(128),
    user_address                            VARCHAR(440),
    boundary_hierarchy                      JSONB,
    boundary_hierarchy_code                 JSONB,
    task_dates                              DATE,
    locality_code                           VARCHAR(128),
    additional_details                      JSONB
);
