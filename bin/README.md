# thirds CLI

To generate a new key pair:

```sh
dart thirds.dart gen_key_pair
```

To create a JWT:

```sh
echo '{"example": "data"}' | dart thirds.dart create_jwt $PRIVATE_KEY
```
