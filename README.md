# 500pxApiChallenge

A multi-paged, scrolling, zoomable application that hooks into 500px's API and displays images and their information from their "popular" features page.

Video of app in action:

[![500px iOS Client](http://i3.ytimg.com/vi/Z0taVhwj3EY/hqdefault.jpg)](https://www.youtube.com/watch?v=Z0taVhwj3EY)

*(click image to visit video link)*

Overall Controller Hierarchy:
-----------------------------
```
RootViewController: UIViewController, UIPageViewControllerDelegate
+-> ModelController: NSObject, UIPageViewControllerDataSource
|   |-> APIManager
|   +-> ValidatedPageDataSubjectCache
|       +-> ValidatedPageDataSubject
+-> RootPageViewController: UIPageViewController
   (|-> ModelController: NSObject, UIPageViewControllerDataSource)
    +-> PageViewController: UIViewController, UIScrollViewDelegate
        +-> PageDataSubject
```
I chose this layout after using a "multi-paged" application template provided in Xcode 10.1.2 on my hackintosh running High Sierra. I soon found out that RxSwift
wasn't being supported anymore in cocoa pods for that version of Xcode, so I had to continue developing on my laptop running Xcode 11.2 on Mojave (which explains
why the application template doesn't appear in Apple's default application templates for 11.2.)

I modified the template to fit my needs, and unfortunately Apple's controller class naming conventions are a little different than the conceptual implementation,
but I made do. Basically, RootViewController contains a ModelController, and generates a RootPageViewController and sets ModelController as 
RootPageViewController's data source. ModelController passes instances of PageViewController to RootPageViewController whenever RootPageViewController requests a
new page to be displayed.

I chose RxSwift as a way to avoid messy callback methods and complicated structures that pass API data after calls are asynchronously made by the APIManager,
essentially making image redraws and image data passing much easier to program and understand.

ModelController:
----------------
The ModelController is in charge of generating and providing RootPageViewController with PageViewControllers.
The ModelController primarily contains an APIManager and a ValidatedPageDataSubjectCache (which I will refer to simply as a "the page data cache".)
When the ModelController is initialized, It prefetches and caches the first page's data to retrieve an accurate page count from the API. Once the data arrives
(via a pageDataSubject subscription) it updates the total page count and resets the RootPageView's data source, so it can regenerate RootPageView's
UIViewController array and allow us to move past the first and only page that exists whenever we start up the application.
Otherwise, the general call structure looks like this for ModelController:
```
1. ModelController receives a request for a UIViewController (at some page index) from RootPageViewController
2. i) The ModelController checks the page data cache for a valid page data subject at the provided index
  ii) A page data subject is procured (as explained in the following scenarios) which is passed into a new PageViewController's initializer.
      a) The page data exists and is valid: the cached page data subject is returned.
      b) The page data exists but is invalid (meaning the data is "stale", or exceeds the cache lifetime in the API documentation (5 minutes)): new data is fetched from the API for that page data subject using APIManager, it is re-validated and returned.
      c) The page data does not exist: APIManager is called to fetch the appropriate data, creating and returning a new page data subject.
3. The PageviewController is returned and passed back to the RootPageViewController.
```
When the RootPageViewController requests the next or previous PageViewController, I trigger an additional fetch for the page after/before that one. When the 
connection is quick, this lets the user see the images quicker. As a downside, slower connections aren't ideal for this feature, and since I've chosen a black
background for each UIImage, it doesn't help indicate to the user that the page data has been fetched but the images are still loading (as the images are 
practically invisible). If I had more time, I would add a rotating loading indicator as the default UIImage for a UIButton, that way the user understands that 
the images are on their way. If the user keeps switching pages quickly this prefetching could also be problematic and cause slowdowns. Luckily, people don't 
usually skip through pages like this and will take a few seconds to look at each page, but ideally, I would have implemented a way to prevent this and make 
the process more efficient. 

Page Data Subjects and Page Data:
---------------------------------
Page data subjects are essentially `BehaviorSubjects<PageData>` types, where PageData is a nested `Codable` data structure that APIManager uses to decode 
returned JSON requests from the API into a nested struct format. I've cherry-picked potentially important JSON keys from the API and used them to build 
the following data structures:
```
struct PageData: Codable
|-> currentPage: Int
|-> totalPages: Int
|-> totalItems: Int
|-> feature: String
+-> photos: [ImageData]

struct ImageData: Codable
|-> name: String
|-> user: User
|-> description: String
|-> createdAt: String
|-> commentsCount: Int
|-> votesCount: Int
|-> positiveVotesCount: Int
|-> timesViewed: Int
+-> images: [Image]

struct Image: Codable
|-> format: String
|-> size: Int
|-> url: String
+-> httpsUrl: String
```
PageViewControllers each contain a page data subject for thier respective page in the API. Whenever the data is updated, the PageViewControllers are notified
through subscriptions, essentially allowing them to asynchronously update the data they display whenever the API manager is told to send updates through their
page data subscriptions. The page data cache contains a class called ValidatedPageDataSubject that is just a wrapper struct around a page data subject. This
type starts a `Timer` whenever it is created or re-validated, which automatically invalidates itself after the allotted time runs out (set at 5 min, which is
listed in the 500px API documentation as the API data cache lifetime.)

PageViewController:
-------------------
Subscribes to its corresponding page data subject when initialized, which triggers a page information refresh (and a redraw) whenver the subject updates with new 
data. The UI here is flexible for every device size and orientation, displaying images in a grid that can be zoomed in/out by pinching out/in, respectively. 
Zooming is disabled in the UIScrollView, as horizontal panning is not suitable for a paged view controller setup like this, so a pinch gesture recognizer has 
been implemented to trigger on pinches instead. It cycles between 3 levels of draw scale, where the columns displayed in the grid go from 4 <-> 2 <-> 1. Pinch 
ins decrease the image draw scale, increasing the columns displayed on the UIScrollView, and vice versa. The images displayed are implemented as UIButtons, 
which asynchronously load an image from a URL only when the page data subject is updated (which also triggers a complete image data refresh.) Whenever an image 
button is pressed, it increases the draw scale in the PageViewController to the maximum scale level. This triggers a redraw that displays the images on a grid 
with one column, automatically scrolling to that image button in the UIScrollView. This draw scale level also includes image details that are implemented as an 
`ImageInfoView` type. This custom view displays the image title, username and full name in parentheses, view count, positive rating count, comment count and 
description of the image (all supplied by the `ImageData` struct above.) When the draw scale is reduced, every ImageInfoView is removed from the UIScrollView
and a 2 or 4 column grid of image buttons is drawn.

I added a feature that remembers the topmost image in the view after the user finishes scrolling/dragging on any draw scale. Pinching in/out will force the 
UIScrollView to attempt to scroll to that image's y-coordinate in its content bounds after the redraw occurs, displaying it at the top of the grid. This is a 
more intuitive and useful funcionality that is especially useful if the user zooms in from the middle draw scale. It's less disorienting if the first visible 
image is chosen as the first image shown at the largest draw scale, instead of defaulting to the first image button in the entire UIScrollView. This image 
button is remembered after zooming out completely, so long as the user doesn't scroll around. I used to animate the redraws that happened after each draw scale
change, but the way I implemented the redraws made this very disorienting and jarring at the middle and highest draw scale, so I disabled animations. If I had 
more time, I would instead implement a more useful zoom redraw that animates the images correctly for this feature.

Orientation changes on the device were actually the primary reason for remembering the topmost visible image. whenever the device orientation changes, a redraw 
of the entire UIScrollView occurs to rescale every image button in the UIScrollView. If this doesn't happen, the images will remain at the exact same scale and 
positions as they did before, which is less than ideal now that the UIScrollView frame has completely changed. Redraws don't show the last-seen image at the top 
of the screen by default, so it has to be forced (without animations) once the redraw is finished. 

A design implmentation I was considering (but cut due to time constraints) was a user-triggered API fetch that refreshes the current page's page data subject. 
The user would drag down from the topmost point in the UIScrollView to reveal a refresh icon. Letting go at this point would trigger a call to APIManager that
would update the page data subject when finished, which would redraw the current page. This would be paired with a notification that appears on the UIScrollView 
whenever the API isn't available for some reason on a data refresh or when a new PageViewController is initialized. The user could then trigger another refresh 
by swiping down and refreshing the page repeatedly until images are loaded in successfully.

Another feature I was considering was swapping UIImages whenever the draw scale is increased to the max value. This would improve how images appear at this scale,
but since the API currently only provides a single image size per image when fetching the entire page's data, this would require making individual calls for each
image. I wanted to keep the calls to a minimum, so this wasn't implemented.

------------------------------------------------------------------------------------------------------------------------------------------------------------------

Requirements:
-------------
```
-> Any Xcode version that supports iOS 13.0+ 
   (I used Xcode 11.2)
-> Any simulator device supporting iOS 13.0+ 
   (iPhone and iPad decices are both supported by the UI layouts. The low-quality images will look better on devices with smaller screens though. 
    Unfortunately I don't have any Apple devices that support iOS 13.0+, so I could only test this with simulated devices running iOS 13.0+ using Xcode.)
```

The reason I why chose iOS 13.0+ is because it is the first iOS that supports the new System symbols supplied by Apple 
(which I used inside ImageInfoView for the "username", "thumbs up" (positive ranks), total "views", and total "comments" information for each image.)

API Consumer Key Setup Steps + Instructions For Running This Application:
-------------------------------------------------------------------------
```
1. Clone the 500pxApiChallenge project
2. Create a new blank text file called "API.key", pasting a raw consumer key value for the 500px API inside on the first line.
   (I used Sublime to create/edit the file, as it is capable of opening weird file formats.)
3. Place the new file inside at the following location inside the project: "/500pxApiChallenge/500pxApiChallenge/Assets/API.key".
   (Creating the Assets folder, if necessary.)
4. Open the project in Xcode and Build/Run/Test the project as normal!
```
