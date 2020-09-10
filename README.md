# rename-photo
A script for renaming photos in a sortable way (using EXIF data and some handy parameters) so you can combine all of your holiday snaps in one folder even though they were taken by 5 different devices.

## Usage
Dot source the file `RenamePhoto.ps1`. That is, run this command from powershell:

    . .\RenamePhoto.ps1

Now the `Rename-Photo` function will be available.

## Examples

### Example 1: Rename a file

    Rename-Photo -FileName IMG_0011.jpg -FileIndex 0 -TagName Martinique_Sally

The file will be renamed to:

    2017-11-10_Martinique_Sally_iPhone8Plus_141210.jpg

Where:

* `2017-11-10` -- is a sortable representation of the date the photo was taken (from the Date taken EXIF data). If the file doesn't have the relevant EXIF data (for example if it's a png file) then the LastWriteTime is used instead.
* `Martinique_Sally` -- is the tag name you've supplied as a parameter. You can add tags (such as location, photographer, ...) to filename, this can be helpful if you need to sort photos later. The default value is "IMG" if `-TagName` is ommited.
* `iPhone8Plus` -- is the device by which the photo was taken. This item will be omitted if there's no EquipModel EXIF data.
* `141210`-- is the datetime index for sorting files. `HHmmss` of DateTaken time will be used if you specify `0` to `-FileIndex`.

### Example 2: Rename multiple files

    dir *.jpg | Rename-Photo -FileIndex 11 -Verbose

This will rename all of the jpg files in the current folder, to have a filename like this:

    2017-11-10_IMG_iPhone8Plus_0011.jpg
    2017-11-10_IMG_iPhone8Plus_0012.jpg
    2017-11-10_IMG_iPhone8Plus_0013.jpg
    ...

If the value you passed to `-FileIndex` is greater than `0`, it will be the start index of the renamed files.

### Example 3: Rename video files
There's one more parameter `-IsVideo` for renaming video files

    dir *.mov | Rename-Photo -FileIndex 11 -TagName MOV -IsVideo
    
This will use the "Media Created" instead of "Date Taken", or if both dates are not available then the LastWriteTime is used.

## Notes
If you've made a small mistake, the script can be re-run. There's no limit on how many times you can re-name the same file.

Also, you can run this script with datetime index and then with start index to get all the files sorted by date.

## Related Links

* [Your photos are a mess! Maybe this PowerShell script can help](http://secretgeek.net/renamephoto)
