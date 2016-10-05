# Virtual Tourist

Virtual Tourist is an app that allows users to tour the world without leaving
the comforts of their couch. This app allows you to drop pins on a map and pull
up Flickr images associated with that location. Locations and images are stored
using Core Data.

## Usage

* Map - Upon launch a user is presented with a full-page map. This screen will
allow for the placement of pins upon tapping on the screen and holding for half
a second. The user will see a pin drop for the selected location on the map.
Pins can also be deleted by selecting the edit button in the top right corner of
this page. This will essentially place the app in 'edit mode' and all pins that
are tapped on will be deleted. Editing can be exited subsequently by tapping
'done'. The current zoom level and location of the map will be saved upon
termination of the app for replacement at these levels upon further launch. A
pin can be selected which will show the album page via a navigation controller.

* Album - Upon launch of the album screen, 21 photos will be retrieved for the
current coordinates of the selected pin and are displayed in a collection view.
A new collection of photos can be chosen for viewing, or individual photos can be
selected and deleted in order to customize the album for each particular pin.
All photos and pins will be persisted utilizing CoreData. The pin that is
currently selected can be viewed in the small map view at the top of this screen.
The 'OK' bar button item in the top left of the screen can be selected to return
to the map view.
