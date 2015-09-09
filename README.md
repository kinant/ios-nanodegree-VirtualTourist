# ios-nanodegree-VirtualTurist
Project 4 of Udacity iOS Nanodegree

# EXTRAS:

- Draggable pins
- Additional Attractions entity shows nearby attractions based on pin location
- Pin and Attraction annotations are customized
- Photos are pre-fetched when the pin is added, so no need to go to Pin Detail View to download images
- Pin has activity indicator that shows up on the annotation on the map. It shows the status of the getting of attractions and downloading of photos. 
- Photos automatically deleted using code in the Photos managed object

# NOTES:

- If attraction pins bother the view, you can toggle them on or off with the hide or show attractions button
- For some reason, I sometimes get the following error when adding a pin: "*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -_referenceData64 only defined for abstract class.  Define -[NSTemporaryObjectID_default _referenceData64]!'"

- The above error occurs randomnly. It could be on the first pin being added or the hundredth pin being added. I have yet to fix this issue. 
