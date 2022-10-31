# Map Explorer

This app uses MapKit to allow users view maps.
The map begins at the current user location.
It can be panned, zoomed, rotated, and tilted for a 3D effect.
The 3D effect is much more pronounced at popular locations
for which Apple has provided more map detail.

The map can also be positioned by searching for an address.
For example, tap the magnifier glass icon in the upper-left,
tap the "Address" tab, enter "Navy Pier", and tap "Navy Pier Ferris Wheel".

- Tap the magnifier glass icon in the upper-left.
- Tap the "Address" tab.
- Enter part of an address such as a street or city name.
- Tap one of the matches displayed in the list below the text input.

Map views can be saved using CloudKit.
Each saved map view is given an area name such as "London" or "Yellowstone" and
an attraction name such as "Buckingham Palace" or "Grand Prismatic Spring".
To save the current map view:

- Tap the heart icon in the upper-right.
- Select an existing area name or tap "New Area" to add one.
  After tapping "New Area", enter the area name and tap the "Add" button.
- Enter an attraction name and tap the "Add" button.

To recall a saved map view:

- Tap the magnifier glass icon in the upper-left.
- Tap the "Attraction" tab.
- Select an area to display a list of saved attractions in that area.
- Tap an attraction name.

Users can search for specific kinds of places near the current map location.
Examples include parks and restaurants of specific types such as "pizza".
Matching places are displayed with map annotations.
To search for places:

- Tap the magnifier glass icon in the upper-left.
- Tap the "Place Kind" tab.
- Enter a place kind like "pizza" or "park".
- Tap the "Search" button.
- Zoom out on the current map to see annotations for the matched places.
- Tap an annotation to display its place name, phone number, and address.
- Tap the "Website" button to display the place website
  in a sheet within the app.

To adjust settings, tap the gear icon in the upper-right.

The settings sheet supports customizing the following map characteristics:

- type
  - Standard - drawing with road names
  - Image - satellite image without road names
  - Hybrid - satellite image with road names
  
- elevation - only affects Image and Hybrid map types
  - Flat - less detail
  - Realistic - more detail
  
- emphasis - only affects the Standard map type
  - Default - full color
  - Muted - muted colors for better display of overlays

The settings sheet also contains buttons
for exporting and importing map attractions in a JSON file.
This is useful for sharing saved map views with others.
