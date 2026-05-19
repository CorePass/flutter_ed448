# flutter_ed448 CLI

To generate a new key pair:

```sh
dart run flutter_ed448:flutter_ed448 gen_key_pair
```

To create a JWT:

```sh
echo '{"example": "data"}' | dart run flutter_ed448:flutter_ed448 create_jwt $PRIVATE_KEY
```
