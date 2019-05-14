AvoidableScrollView
=====
Avoidable scrollview written in swift based ENTIRELY on the "[TPKeyboardAvoiding](https://github.com/michaeltyson/TPKeyboardAvoiding)" project

The idea is basically the same, "a solution to move textfields out of the way of the keyboard".


Introduction
----
There are a hundred and one proposed solutions out there for how to move `UITextField` and `UITextView` out of the way of the keyboard during editing -- usually, it comes down to observing `UIKeyboardWillShowNotification` and `UIKeyboardWillHideNotification`, or implementing `UITextFieldDelegate` delegate methods, and adjusting the frame of the superview, or using `UITableView`'s `scrollToRowAtIndexPath:atScrollPosition:animated:`, but most proposed solutions tend to be quite DIY, and have to be implemented for each view controller that needs it.

This is a relatively universal, drop-in solution: `UIScrollView` and `UITableView` subclasses that handle everything.

When the keyboard is about to appear, the subclass will find the subview that's about to be edited, and adjust its frame and content offset to make sure that view is visible, with an animation to match the keyboard pop-up. When the keyboard disappears, it restores its prior size.

It should work with basically any setup, either a UITableView-based interface, or one consisting of views placed manually.

It also automatically hooks up "Next" buttons on the keyboard to switch through the text fields.


Usage
-----
to use it just drop the `Classes` folder into your project, 

if you want to use with `UIScrollView`, just set your ScrollView class to `AvoidableScrollView`, to use it with `UITableView` is basically the same, just set the base classe to `AvoidableTableView`

To disable the automatic "Next" button functionality, change the UITextField's return key type to anything but UIReturnKeyDefault.

Notes
-----

These classes currently adjust the contentInset parameter to avoid content moving beneath the keyboard.  
This is done, as opposed to adjusting the frame, in order to work around an iOS bug that results in a jerky animation where the view jumps upwards, before settling down.  
In order to facilitate this workaround, the contentSize is maintained to be at least same size as the view's frame.

License
-----
AvoidableScrollView is available under the MIT license. See the [LICENSE](https://github.com/pogramos/AvoidableScrollView/blob/pogramos-patch-1/LICENSE.md) file for more info.
