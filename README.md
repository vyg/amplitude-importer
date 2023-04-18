# Amplitude Bulk Uploader

For bulk uploading/backfilling data into an Amplitude project based on an export of project data.

This script is inspired by and updated from [here](https://github.com/ello/amplitude-import/tree/master)

Simply download your existing project data from Amplitude and point the script to the folder. It will parse and upload the files, log them to a plain text file and should you end up cancelling the script at anytime, it will allow you to pick up the import where you left off.

---

## Prerequisites

* Get an API key from Amplitude for your project that you wish to import in to.

> ⚠️ (It's recommended to create a new test project to test the import and everything looks as expected before doing this on your production project)

* Export all of your existing project data from Amplitudes project detail pane. Download and unzip the file; this will create a new folder with a bunch of gzip'd files. Great, there's nothing else you need to do here, the script will handle the parsing of the gzip'd data.

---

## Usage

* Install the dependencies

```
bundle install
```

* Run the script

```
API_KEY=<your API key> bundle exec ruby import.rb <path to folder>
```

---

### Credits

Thanks to [ello](https://github.com/ello/amplitude-import/tree/master) for the initial script which this was inspired from