# Lung-AI

### Instructions for how to run these scripts to recreate results. 
+ Download the dataset LIDC-IDRI from https://wiki.cancerimagingarchive.net/pages/viewpage.action?pageId=1966254 
+ Install ultralytics in your enviroment
+ Run the script (another script) convertXML2YOLO.sh for every patient folder 
    +  Finn riktig versjon av script på MMIV!!!
+ Run format_for_seg_yolo.ipynb for crating txt files with the yolo segmentation format, and saving the images with the same name in a desired folder 
    + {lesion ID, x1, y1, x2, y2, ......} (NORMALIZED COORDINATES)
+ Run createOverlappingEdgemap.ipynb for replacing the overlapping edgemap created by different radiologist with 1 for each polygon. And for restrict the lesions with an physical area. 
+ Run create_dataset.ipynb for splitting the whole set into train and val
+ Create the yaml file with the right configuration for the parent folder to the train, val, test folder 
    + SHOW FORMAT
+ Run yolomodel.ipynb 
