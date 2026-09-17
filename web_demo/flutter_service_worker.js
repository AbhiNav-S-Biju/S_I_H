'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "e6afd97b0bb3f5e7cc5067fe8f8b53c1",
"assets/AssetManifest.bin.json": "8dd8942393e01d41cfdb6214efe0d657",
"assets/AssetManifest.json": "5cbc38d07eee47f4ad7a01dad26534b8",
"assets/assets/images/groceries/apple.png": "d04415b0ecdd3e28e094c3e506162c09",
"assets/assets/images/groceries/banana.png": "a855a68a0198bcf3b591b756464ad3a0",
"assets/assets/images/groceries/biscuits.png": "cbb301cb298db815757c898e1553e52b",
"assets/assets/images/groceries/bread.png": "0820faeac199ae3844cb6729ee03a118",
"assets/assets/images/groceries/brinjal.png": "98427d6a86cbc4c8193632d36fcf18d5",
"assets/assets/images/groceries/cabbage.png": "835ebcdaaf5dffa0af7de1e92c671f1b",
"assets/assets/images/groceries/carrot.png": "ba4b3575d06a5d0ebebc3bafd5fec087",
"assets/assets/images/groceries/coconut.png": "954ad12f26f30a477aa02485fab6470e",
"assets/assets/images/groceries/coffee.png": "359a67073d61447152a58e36c0e344ae",
"assets/assets/images/groceries/corn.png": "0f859c32ebaee7be90ea7d4cbb259545",
"assets/assets/images/groceries/dal.png": "27b9e617be35e637e8fafda3ef3983e8",
"assets/assets/images/groceries/eggs.png": "8c0549cb5499858dd538c4cb620f5aa5",
"assets/assets/images/groceries/garlic.png": "0ecfb9c7aec77133850c68d6505a61ea",
"assets/assets/images/groceries/green_chilli.png": "10a810654ac5c1b3d7b541566c2d5b42",
"assets/assets/images/groceries/honey.png": "da1c17b19e1ad3d4b7d613ad147b1e04",
"assets/assets/images/groceries/mango.png": "4941c64ce7a43bb71ca497ff0ef206e4",
"assets/assets/images/groceries/milk.png": "042bd7b551baf7cdeedb92033849638b",
"assets/assets/images/groceries/oil.png": "9a6b3e714c224a6093be63b1ce8cb4cf",
"assets/assets/images/groceries/onion.png": "b90ee928a763fa5dbe5f3a15fbe80110",
"assets/assets/images/groceries/orange.png": "6e2c5ceadadcb9b23a5dca3859eacfc4",
"assets/assets/images/groceries/peas.png": "348ca3bd4914c4d23dc9c08ddfb2491f",
"assets/assets/images/groceries/potato.png": "bdd0c6fefdd91359cbd0dab828b8dc1e",
"assets/assets/images/groceries/rice.png": "853804c892843b41efed635b564db95c",
"assets/assets/images/groceries/salt.png": "15e537b07c1d4110324776eae1798fd7",
"assets/assets/images/groceries/spinach.png": "8d5bed77b1f229d8205e4fe84572ab23",
"assets/assets/images/groceries/sugar.png": "86af3e0d7ef11758dd5f2f85399100dc",
"assets/assets/images/groceries/sugarcane.png": "e7f1cd8de96771cb26d6029d04dc2620",
"assets/assets/images/groceries/tea.png": "340128ae3ce1826f9776331193a8d055",
"assets/assets/images/groceries/tomato.png": "fd5297a5aae0ed5f78d4e2fd5aa8ff88",
"assets/assets/images/groceries/wheat.png": "941a621d1b937026c97c3d538fbe5d68",
"assets/assets/images/objects/apple.png": "16002543cdd572ebd2dc9ac3d292dca7",
"assets/assets/images/objects/banana.png": "bda0c775728719467c7bf98c7e074f0d",
"assets/assets/images/objects/basket.png": "0c3e14428197a5eba5615a7cd696b058",
"assets/assets/images/objects/bell.png": "1745c3ac8038610d2dc1144a22816429",
"assets/assets/images/objects/biscuits.png": "cbb301cb298db815757c898e1553e52b",
"assets/assets/images/objects/book.png": "d0bc1626b9d80a9bab61d0b0582aeb71",
"assets/assets/images/objects/bread.png": "0820faeac199ae3844cb6729ee03a118",
"assets/assets/images/objects/brinjal.png": "98427d6a86cbc4c8193632d36fcf18d5",
"assets/assets/images/objects/cabbage.png": "835ebcdaaf5dffa0af7de1e92c671f1b",
"assets/assets/images/objects/camera.png": "a8ebd728cb4558b008e35d7a0cbc5356",
"assets/assets/images/objects/candle.png": "6402b69cac28526210ccf2fe1a46686b",
"assets/assets/images/objects/cap.png": "14b75fbe9c72c826690029e6f011dba6",
"assets/assets/images/objects/carrot.png": "ba4b3575d06a5d0ebebc3bafd5fec087",
"assets/assets/images/objects/clock.png": "fd7369a60cd1463478f6b3c1a247e791",
"assets/assets/images/objects/coconut.png": "954ad12f26f30a477aa02485fab6470e",
"assets/assets/images/objects/coffee.png": "359a67073d61447152a58e36c0e344ae",
"assets/assets/images/objects/comb.png": "f61d0f5577f8a8fafeb3c2d03cb88868",
"assets/assets/images/objects/corn.png": "0f859c32ebaee7be90ea7d4cbb259545",
"assets/assets/images/objects/dal.png": "27b9e617be35e637e8fafda3ef3983e8",
"assets/assets/images/objects/eggs.png": "8c0549cb5499858dd538c4cb620f5aa5",
"assets/assets/images/objects/garlic.png": "0ecfb9c7aec77133850c68d6505a61ea",
"assets/assets/images/objects/glasses.png": "1aee73c62284b9fb542e59b6688373e6",
"assets/assets/images/objects/green_chilli.png": "10a810654ac5c1b3d7b541566c2d5b42",
"assets/assets/images/objects/handbag.png": "41b7d6bf56f300315111a8b3df79c1bc",
"assets/assets/images/objects/honey.png": "da1c17b19e1ad3d4b7d613ad147b1e04",
"assets/assets/images/objects/key.png": "c4e9a8e205e9f6b59777b9204a458f49",
"assets/assets/images/objects/lamp.png": "501fbfdaa9d7c73fe5d9d4ab5891883e",
"assets/assets/images/objects/mango.png": "4941c64ce7a43bb71ca497ff0ef206e4",
"assets/assets/images/objects/milk.png": "042bd7b551baf7cdeedb92033849638b",
"assets/assets/images/objects/mug.png": "a24076b35e8d20fc32ad6931b2b62fff",
"assets/assets/images/objects/oil.png": "9a6b3e714c224a6093be63b1ce8cb4cf",
"assets/assets/images/objects/onion.png": "b90ee928a763fa5dbe5f3a15fbe80110",
"assets/assets/images/objects/orange.png": "6e2c5ceadadcb9b23a5dca3859eacfc4",
"assets/assets/images/objects/peas.png": "348ca3bd4914c4d23dc9c08ddfb2491f",
"assets/assets/images/objects/pencil.png": "142408ad032569d6c5d12b899b93edec",
"assets/assets/images/objects/plant.png": "43ee516e5c01cfdd59a7c3efa66d4e3b",
"assets/assets/images/objects/potato.png": "bdd0c6fefdd91359cbd0dab828b8dc1e",
"assets/assets/images/objects/radio.png": "5623554f6b53ee49649b5731f1711d8f",
"assets/assets/images/objects/rice.png": "853804c892843b41efed635b564db95c",
"assets/assets/images/objects/rice_bowl.png": "e956ac1744659b4a63a5e5fa80154f84",
"assets/assets/images/objects/rose.png": "1fd584afaef5b2f26fa0013ad303dd57",
"assets/assets/images/objects/salt.png": "15e537b07c1d4110324776eae1798fd7",
"assets/assets/images/objects/scarf.png": "aa47174e3c008d328fab6c72fc15e7ea",
"assets/assets/images/objects/shoe.png": "91054bc82254a422bef192e5cf2db743",
"assets/assets/images/objects/spinach.png": "8d5bed77b1f229d8205e4fe84572ab23",
"assets/assets/images/objects/spoon.png": "b5a0787651263f4dc412ba0f5b3a3f0d",
"assets/assets/images/objects/sugar.png": "86af3e0d7ef11758dd5f2f85399100dc",
"assets/assets/images/objects/sugarcane.png": "e7f1cd8de96771cb26d6029d04dc2620",
"assets/assets/images/objects/sweater.png": "e01907401ff3cd91da70dddf999bbc49",
"assets/assets/images/objects/tea.png": "340128ae3ce1826f9776331193a8d055",
"assets/assets/images/objects/tea_cup.png": "6d812ee76ed1cf7b94b65b736d69dd22",
"assets/assets/images/objects/tomato.png": "fd5297a5aae0ed5f78d4e2fd5aa8ff88",
"assets/assets/images/objects/toothbrush.png": "b0e0a4bd4d8e1336b1758193ccaf7e1b",
"assets/assets/images/objects/umbrella.png": "67d535f956080a037cdec5e0cc099bb2",
"assets/assets/images/objects/wallet.png": "39d13d79fe6d9ec462b01b1d23ec2f1f",
"assets/assets/images/objects/watch.png": "6c57265bdd7a2d9aafb1e4e5d1ba4143",
"assets/assets/images/objects/water_bottle.png": "fc405b84a65c1b6089d4a4106d4320a6",
"assets/assets/images/objects/wheat.png": "941a621d1b937026c97c3d538fbe5d68",
"assets/assets/images/puzzle/puzzle_courtyard_garden.jpg": "18e753992a01d4e87ef2ab9d69ab8572",
"assets/assets/images/puzzle/puzzle_family_gathering.jpg": "a6e8cb249f696ff947688b00dcab6069",
"assets/assets/images/puzzle/puzzle_home_kitchen.jpg": "a75bbf83bc17eaf84c0367861d4efbe7",
"assets/assets/images/puzzle/puzzle_kaziranga_rhino.png": "d0286077e9df757224078ca1d5caf21b",
"assets/assets/images/puzzle/puzzle_meghalaya_falls.png": "5f72c8b98b50418090630698ea1bc821",
"assets/assets/images/puzzle/puzzle_monastery_prayer.png": "3bc72b261c77056dba23fd83821e6d43",
"assets/assets/images/puzzle/puzzle_morning_tea.jpg": "4be9355ec9dde41a042020a5fcad560b",
"assets/assets/images/puzzle/puzzle_seven_sisters.png": "4e936faaef414eb83f605610f770b8f0",
"assets/assets/images/puzzle/puzzle_tawang_monastery.png": "667657ef2ce76db830c76c98c4a1a11a",
"assets/assets/images/puzzle/roadmap_background.jpg": "77bc6451e524d968cc137824574bdb0a",
"assets/FontManifest.json": "5a32d4310a6f5d9a6b651e75ba0d7372",
"assets/fonts/MaterialIcons-Regular.otf": "243cba8ae44c90ec58b19535893cc115",
"assets/NOTICES": "8f277056d7f7c6494885f1b130efb06a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "ed0dee0d8afff0b52ce90900f207125b",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "262525e2081311609d1fdab966c82bfc",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "269f971cec0d5dc864fe9ae080b19e23",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "cd6787199e5d72e5e200c9fcc79b2412",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "c70a135652eca023fc0d323c000c180c",
"/": "c70a135652eca023fc0d323c000c180c",
"main.dart.js": "e608baa0a069be287c922ae9811b4807",
"manifest.json": "dbdfed909fed43b7d19cb5b1f4663c62",
"version.json": "2a59d78e7d6c71acc6702dde384764ba"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
