# Map Explorer

This app uses MapKit to allow users view maps.
The map begins at the current user location.
It can be panned, zoomed, rotated, and tilted for a 3D effect.
The 3D effect is much more pronounced at popular locations
for which Apple has provided more map detail.

The map can also be positioned by searching for an address.
For example, tap the magnifier glass icon in the upper-left,
tap the "Address" tab, enter "Navy Pier", and tap "Navy Pier Ferris Wheel".

Map views can be saved using CloudKit.
Each saved map view is given an area name such as "London" or "Yellowstone" and
an attraction name such as "Buckingham Palace" or "Grand Prismatic Spring".
To recall a saved map view, tap the magnifier glass icon in the upper-left,
tap the "Attraction" tab, select an area to display a list of saved attractions in that area,
and tap an attraction name.

Users can search for specific kinds of places near the current map location.
Examples include parks and restaurants of specific types such as "pizza".
Matching places are displayed with map annotations.
Tapping an annotation displays the place name, phone number, and address.
Tapping the "Website" button displays the website of the place
in a sheet within the app.

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
for exporting and importing map attractions.
This is useful for sharing saved map views with others.
