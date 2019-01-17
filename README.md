# ConoHaセキュリティグループ設定ツール

### requirements

- make
- jq

### セキュリティグループ作成

```
make token
make sg-web4
make sg-ssh4
make ls-security-group
make add_web4_rules
make add_ssh4_rules
```

### セキュリティグループ設定

```
make token
make ls-security-group
make ls-server-port
PORT_ID=xxx make apply-security-group
```