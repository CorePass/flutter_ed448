# thirds

EdDSA/Ed448 JWT support in JS

## Including

`thirds` can run in the browser and Node.js

Web:


```html
<!-- Adds Thirds object to window -->
<script src="./dist/thirds.min.js"></script>
```

Node.js:

```js
const Thirds = require("./dist/thirds.min.node.js");
```

## Examples

```js
// Encode JWT with private key
const secret = (
  "d204c7a9585cca8fa52ff922946046be799a4595f7db24255d9cfbe0d"
  + "d09056350a14d3fe705a5fa715528e4e4a3ba42990f7fdc77db266052"
);
const jwt = Thirds.jwtEncode({example: "data"}, "EdDSA", {key: secret});
console.log(jwt);

// Verify and decode JWT with public key
const public = (
  "b15bc91bf433416df6818919900bc6091587d90eaf00b93d9bedc0b83"
  + "3c9f680f91f2cd2ef5c85e0e3913cd28c5b65a52d844ba9e958f59680"
);
const {verified, decoded, reason} = Thirds.jwtDecode(jwt, "EdDSA", {public: true, key: public});
if (verified) {
  console.log(decoded);
} else {
  console.error(`Failed to verify token: ${reason}`);
}
```

## Development

To build the JS library, run `./tool/to_js.sh` from the root of the repository.
The library will be generated in `js/dist`.
