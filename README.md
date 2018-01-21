# Description

Simulator Data Finder is an utility to help you access the files in the xcode iOS Simulator.
It will present you with list of accessible simulator and the application installed on each simulator.
It will let you easily and quickly access with the finder:

the documents directory in the data container (you need to add a macro to your application delegate for that to work)
the application bundle
the device directory
any containers downloaded from the device for a specific app (you need to save them in the downloads folder)

## Setup

1. The first time you start the program, it will ask you to authorize read access to the directory containing the simulators. It will try to guess based on the standard location, otherwise please point it to the correct directory and press authorize.
2. the iOS Simulator changes the data container directory each time it starts. Simulator Data Finder will try to work out the folder, but does not always find it. For Simulator Data Finder to find it easily, you can save a small header file (from the help button or from the help menu or download here ), include it in your project and add the macro to your application delegate didFinishLaunchingWithOptions. It will save a hidden zero size file to easily find the directory later. The help and the comment on the header file will give you details.
3. If you use swift, you can import the following file into your project. The file contains instruction how to modify the Application Delegate in a swift project
4.	When you select an app, it will give you easy access in the download section to data container saved from a device (from xcode/devices function), if you saved them in your downloads directory.

![SnapShot](https://ro-z.net/blog/wp-content/uploads/2015/01/Simulator_Data_Finder_and_Edit_Post_%E2%80%B9_ConnectStats_Blog_—_WordPress_and_PassportLucExp2022_pdf.png)