# Adding a region

English | [한국어](adding-a-region.ko.md)

Regions cannot be added from the app. You change the design and the code, then build the app yourself. There are three regions now: Seoul, Busan, and Henesys.

Each real city has one landmark in the distance outside the window. Everything else (the room, the person, the cat, and the events) is the same in every city. A region can also bring a whole design of its own, like Henesys (see "Adding a design" below).

## 1. Design the far view

The design files are in [`design/`](../design/). They are plain HTML. Open them through any static server run in that folder, for example `python3 -m http.server` or [hunsu](https://github.com/zzzinho/hunsu).

1. In `design/00-base.html`, add a drawing function to `FAR_VIEWS`, and map the region's Korean name to it in `REGION_VIEWS`. A region that is not in `REGION_VIEWS` gets the default view: a ridge with apartment blocks.
2. Copy `design/01-busan.html` to `design/NN-<region>.html` and change only `REGION` (the name and the design intents). The page fetches the drawing code from `00-base.html`, so open it through the server, not as a file.
3. In `design/DESIGN.md`, add a row to the table of regional far views (지역별 먼 풍경): what the landmark is and why it was chosen. Draw only one landmark per region. The widget is small, and two landmarks are both lost.

## 2. Port it to the app

The drawing code in `ChristofKit` is a port of the design's JavaScript, with the same names and order, so it draws the same dots.

1. Port the drawing function to a `FarView` type in `ChristofKit/Sources/ChristofKit/Rendering/Layers/FarViews.swift`.
2. Add the region to `KoreaRegions.all` in `ChristofKit/Sources/ChristofKit/Countries/Korea/KoreaRegions.swift`:

   ```swift
   region("daegu", LocalizedName(en: "Daegu", ko: "대구"), 35.87028, 128.59111, radius: 15_000, RegionLooks(far: DaeguView())),
   ```

   - The id (`KR.daegu`) is saved in widget settings. Do not change it after a release.
   - The Korean name must match the key in `REGION_VIEWS`. The design comparison uses it to pick the far view.
   - The coordinates are the city center. The sun and moon are computed for this point. Weather always comes from the device's location, whatever region is chosen; when the location cannot be read, it comes from the region last picked by location. The current regions use the center point from [Open-Meteo geocoding](https://open-meteo.com/en/docs/geocoding-api).
   - When a widget's region is Auto, the app and the widget look up the city of the device's location with Apple's reverse geocoding, in English, and pick the region with that English name. So the English name must be the city name that Apple Maps uses. Outside every region, Auto draws the device's own location with the default far view.
   - `radius` is the rough distance in meters from the center to the city boundary. It is used only when reverse geocoding fails, for example offline.
   - The first region in the list is the default region. Auto uses it only when it has never received the device's location.

The widget's region list and the app's region picker read the regions from `CountryRegistry`, so no other code changes.

## 3. Check

To compare the new far view with the design, add a scene with the new region to `scenarios` in `ChristofKit/Sources/ChristofSnapshots/main.swift`. Then run:

```sh
swift test --package-path ChristofKit
swift run --package-path ChristofKit ChristofSnapshots /tmp/christof-snapshots
node ChristofKit/Scripts/compare-design.mjs /tmp/christof-snapshots design/00-base.html
```

The comparison redraws every snapshot with the design's JavaScript. The palette and every grid must match. Open the PNGs in the snapshot folder to look at the result too.

Build the app with:

```sh
xcodebuild -project Christof.xcodeproj -scheme Christof -destination 'platform=macOS' build
```

## Adding a design

A design changes the town outside the window, the window frame, the animal in the cat's spot, and the everyday outfit. It comes with its own region, and there is no separate design setting.

1. Design it as a theme page like `design/03-henesys.html` (`THEMES` in `design/00-base.html`).
2. Port it to a `Theme` value in `ChristofKit/Sources/ChristofKit/Rendering/Themes/`: the town (`OutsideEffect`), the frame (`WindowFrame`), the animal (`Pets`), and the outfit (`Outfit`). See `Henesys.swift`.
3. Add a region with that theme to `KoreaRegions.all`. A place that does not exist gets `radius: 0`, so Auto never picks it:

   ```swift
   region("henesys", LocalizedName(en: "Henesys", ko: "헤네시스"), 35.10168, 129.03004, radius: 0, RegionLooks(theme: .henesys)),
   ```

   It takes Korea's holidays, seasons, and time zone, and the sun and moon of the coordinates you give.
4. Add its scenes to the snapshots and compare them as in "Check".

The app's region picker and the widget's region list pick it up. No other code changes.

## Adding a country

1. Make a folder `ChristofKit/Sources/ChristofKit/Countries/<Country>/` with a type that conforms to `CountryProfile`: the country code, regions, holidays (`occasions`), and seasons.
2. Add the profile to `CountryRegistry.standard`. Shared code does not change.

A holiday is one `Occasion` value: a date rule (`OccasionRule`) and the looks for each part of the scene. See `Countries/Korea/KoreaOccasions.swift` for examples. Draw each country with its own landscape and customs, so it is never mistaken for another country. `design/DESIGN.md` has the rules.
