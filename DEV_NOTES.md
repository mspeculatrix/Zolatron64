# DEV NOTES

## APPS

To upload an app to the Zolatron's Raspberry Pi, from the app's subdir use `zapp`.

This defaults to uploading to the host `zd0`. To upload to another host, use (eg):

`zapp -h imp`

The app is built before uploading to ensure the latest iteration is uploaded.

ROM apps work the same way - just use the `-r` flag. (Again, you need to be in the app's directory).

You can also upload individual files. From the same directory as the file, use:

`zapp -f <filename>`
