Application for getting information about current stituation of running train.

# Usage

`get_vr_info.sh --train 42 --destination "Tampere asema"`

Output:
```json
{
    "actualDifferenceInMinutes": -1,
    "estimatedArrivalTime": "2019-02-20 15:55:21",
    "estimatedDifferenceInMinutes": 0,
    "latestStation": "Lempäälä",
    "targetStation": "Tampere asema",
    "trainNumber": 45,
    "trainType": "S",
    "updatedTime": "2019-02-20 15:46:12"
}
```

# Install (mac)

$ mkdir ~/bin
$ cd ~/bin
$ ln -s /path/to/location/of/this/file/get_vr_info.sh get_vr_info.sh
$ echo "# ADD ~/bin FOLDER INTO PATH" >> ~/.bash_profile
$ echo "export PATH=$PATH:~/bin" >> ~/.bash_profile 
