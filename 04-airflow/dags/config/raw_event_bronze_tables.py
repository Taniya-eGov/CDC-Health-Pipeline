"""
Configuration for Raw Event -> Bronze extraction.

Each entry represents one independent:

    Raw Event table -> Bronze table

To add a new table:

1. Create the Raw table.
2. Create the Bronze table.
3. Add one configuration entry here.
4. The DAG automatically creates a mapped task for it.

No DAG code changes are required.

Keys per entry:

    name          Table key. Also the map index shown in the Airflow UI.
    raw_table     Fully qualified event store table.
    bronze_table  Fully qualified stg_* table.
    page_size     Raw events read per keyset page.
    columns       Debezium `after` key -> Bronze column. Both sides are
                  validated at run time: every Bronze column must exist in
                  system.columns, and every configured source key must appear
                  in the actual event payload. A typo fails the task instead of
                  silently loading ''/0/False.

Optional:

    allow_null_after   Default False. The processor fails a table if any raw
                       event has a null `after`, because only CREATE and UPDATE
                       are expected here and both carry a row image -- a null
                       one is silent data loss. Set True only to deliberately
                       accept that loss and let the table proceed.
"""


RAW_EVENT_BRONZE_TABLES = [

    {
        "name": "household",

        "raw_table": "analytics.household_events_raw",

        "bronze_table": "analytics.stg_household",

        "page_size": 10000,

        "columns": {
            "id": "id",
            "tenantid": "tenant_id",
            "clientreferenceid": "client_reference_id",
            "numberofmembers": "member_count",
            "householdtype": "household_type",
            "addressid": "address_id",
            "additionaldetails": "additional_details",
            "createdby": "created_by",
            "lastmodifiedby": "last_modified_by",
            "createdtime": "created_time",
            "lastmodifiedtime": "last_modified_time",
            "clientcreatedtime": "client_created_time",
            "clientlastmodifiedtime": "client_last_modified_time",
            "clientcreatedby": "client_created_by",
            "clientlastmodifiedby": "client_last_modified_by",
            "rowversion": "row_version",
            "isdeleted": "is_deleted",
        },
    },

    {
        "name": "project_task",

        "raw_table": "analytics.project_task_events_raw",

        "bronze_table": "analytics.stg_project_task",

        "page_size": 10000,

        "columns": {
            "id": "id",
            "clientreferenceid": "client_reference_id",
            "tenantid": "tenant_id",
            "projectid": "project_id",
            "projectbeneficiaryid": "project_beneficiary_id",
            "projectbeneficiaryclientreferenceid":
                "project_beneficiary_client_reference_id",
            "plannedstartdate": "planned_start_date",
            "plannedenddate": "planned_end_date",
            "actualstartdate": "actual_start_date",
            "actualenddate": "actual_end_date",
            "addressid": "address_id",
            "additionaldetails": "additional_details",
            "createdby": "created_by",
            "createdtime": "created_time",
            "lastmodifiedby": "last_modified_by",
            "lastmodifiedtime": "last_modified_time",
            "rowversion": "row_version",
            "isdeleted": "is_deleted",
            "clientcreatedtime": "client_created_time",
            "clientlastmodifiedtime": "client_last_modified_time",
            "clientcreatedby": "client_created_by",
            "clientlastmodifiedby": "client_last_modified_by",
            "status": "status",
        },
    },

    # ------------------------------------------------------------------
    # Add remaining tables here.
    # ------------------------------------------------------------------

    # {
    #     "name": "address",
    #     "raw_table": "analytics.address_events_raw",
    #     "bronze_table": "analytics.stg_address",
    #     "page_size": 10000,
    #     "columns": {
    #         "id": "id",
    #         "tenantid": "tenant_id",
    #         ...
    #     },
    # },

]