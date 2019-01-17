IDENTITY_ENDPOINT := https://identity.tyo2.conoha.io/v2.0
NETWORKING_ENDPOINT := https://networking.tyo2.conoha.io

WORKING_PATH := /tmp
TOKEN_PATH := $(WORKING_PATH)/tokens.json
SG_INFO_PATH := $(WORKING_PATH)/security-groups.json
SG_WEB4_NAME := $(PREFIX)_def_web4
SG_SSH4_NAME := $(PREFIX)_def_ssh4

.PHONY: token ls-security-group sg-web4 sg-ssh4 set_web4_id set_ssh4_id add_web4_rules add_ssh4_rules apply-security-group clean

token:
	$(eval AUTH_JSON := $(shell jq '.auth.passwordCredentials |= .+ {"username": "$(API_USERNAME)", "password": "$(API_PASSWORD)"}' auth.json | jq '.auth |= .+ {"tenantId": "$(API_TENANT_ID)"}'))
	@curl -sS -X POST -H "Accept: application/json" -d '$(AUTH_JSON)' -o $(TOKEN_PATH) $(IDENTITY_ENDPOINT)/tokens
	@cat $(TOKEN_PATH) | jq "."

set_token:
	$(eval TOKEN := $(shell jq -r ".access.token.id" $(TOKEN_PATH)))

ls-security-group: set_token
	@curl -sS -X GET -H "Accept: application/json" -H "X-Auth-Token: $(TOKEN)" -o $(SG_INFO_PATH) $(NETWORKING_ENDPOINT)/v2.0/security-groups
	@cat $(SG_INFO_PATH) | jq "."

sg-web4: set_token
	$(eval SECURITY_GROUP_JSON := $(shell jq '.security_group |= .+ {"name": "$(SG_WEB4_NAME)"}' security-group.json))
	@curl -sS -X POST -H "Accept: application/json" -H "X-Auth-Token: $(TOKEN)" -d '$(SECURITY_GROUP_JSON)' $(NETWORKING_ENDPOINT)/v2.0/security-groups | jq "."

sg-ssh4: set_token
	$(eval SECURITY_GROUP_JSON := $(shell jq '.security_group |= .+ {"name": "$(SG_SSH4_NAME)"}' security-group.json))
	@curl -sS -X POST -H "Accept: application/json" -H "X-Auth-Token: $(TOKEN)" -d '$(SECURITY_GROUP_JSON)' $(NETWORKING_ENDPOINT)/v2.0/security-groups | jq "."

set_web4_id:
	$(eval SG_WEB4_ID := $(shell jq -r '.security_groups[] | select(.name == "$(SG_WEB4_NAME)") | .id' $(SG_INFO_PATH)))

set_ssh4_id:
	$(eval SG_SSH4_ID := $(shell jq -r '.security_groups[] | select(.name == "$(SG_SSH4_NAME)") | .id' $(SG_INFO_PATH)))

add_web4_rules: set_token set_web4_id
	$(eval HTTP_JSON := $(shell jq '.security_group_rule |= .+ {"security_group_id": "$(SG_WEB4_ID)"}' http-rule.json))
	$(eval HTTPS_JSON := $(shell jq '.security_group_rule |= .+ {"security_group_id": "$(SG_WEB4_ID)"}' https-rule.json))
	curl -sS -X POST -H "Accept: application/json" -H "X-Auth-Token: $(TOKEN)" -d '$(HTTP_JSON)' $(NETWORKING_ENDPOINT)/v2.0/security-group-rules | jq "."
	curl -sS -X POST -H "Accept: application/json" -H "X-Auth-Token: $(TOKEN)" -d '$(HTTPS_JSON)' $(NETWORKING_ENDPOINT)/v2.0/security-group-rules | jq "."

add_ssh4_rules: set_token set_ssh4_id
	$(eval SSH_JSON := $(shell jq '.security_group_rule |= .+ {"security_group_id": "$(SG_SSH4_ID)"}' ssh-rule.json))
	curl -sS -X POST -H "Accept: application/json" -H "X-Auth-Token: $(TOKEN)" -d '$(SSH_JSON)' $(NETWORKING_ENDPOINT)/v2.0/security-group-rules | jq "."

ls-server-port: set_token
	curl -sS -X GET -H "Accept: application/json" -H "X-Auth-Token: $(TOKEN)" $(NETWORKING_ENDPOINT)/v2.0/ports | jq ".ports[] | {id: .id, name: .name}"

apply-security-group: set_token set_web4_id set_ssh4_id
	$(eval SECURITY_GROUPS_JSON := $(shell jq '.port.security_groups |= .+ ["$(SG_WEB4_ID)","$(SG_SSH4_ID)"]' security-groups.json))
	curl -sS -X PUT -H "Accept: application/json" -H "X-Auth-Token: $(TOKEN)" -d '$(SECURITY_GROUPS_JSON)' $(NETWORKING_ENDPOINT)/v2.0/ports/$(PORT_ID) | jq "."

clean:
	rm -f $(TOKEN_PATH)
