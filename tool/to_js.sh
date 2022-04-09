dart2js -O4 -o dist/thirds.min.js tool/js_main.dart
(dart tool/print_node_preamble.dart | cat - dist/thirds.min.js) > dist/thirds.min.node.js
