dart2js --no-source-maps -O4 -o js/dist/thirds.min.js js/main.dart
(dart js/print_node_preamble.dart | cat - js/dist/thirds.min.js) > js/dist/thirds.min.node.js
