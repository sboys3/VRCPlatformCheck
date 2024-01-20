# U# VR Chat Platform information
A small U# tool to determine information about the platform a vrchat world is running on.

One of the unusual abilities of this tool is the ability to distinguish the Quest 2 from the Quest 3.
It uses a shader to detect a bug in the Quest 2's GPU. 

## Instructions
1. Copy this repository into a folder in your assets folder using git clone or downloading the zip under the code button
2. Drag the PlatformCheckRenderTarget prefab into your scene. Make sure that there is nothing in the camera view on the first custom layer. You can place it at something like Y -10000 to keep it away from things.
3. Create a script with a public function named OnPlatformCheck. This function will be called when the platform info is ready. See the example below.
4. Place your script on the RenderTargetCam GameObject or if you need it elsewhere, you can add it to the Callback Scripts list on the VRCPlatformCheck component that is located on RenderTargetCam.


### Example of Script
This is an example of a script that computes a quality value from the platform info that could be used to scale performance in things like raymarching shaders. This script requires that the VRCPlatformCheck component is set for platformInfo in the editor inspector.
```c#
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class DepthTest : UdonSharpBehaviour
{
	public VRCPlatformCheck platformInfo;
	public float quality = 1;
	
	public void OnPlatformCheck(){
		if(platformInfo.isReversedZ){
			// probably pc or at least a competent GPU
			quality = 1.0f;
		}else{
			// probably on mobile or possibly some old desktop gpu
			// decrease quality for mobile devices such as the quest 3
			quality = 0.3f;
			
			if(platformInfo.isAdreno600){
				// on scuffed adreno GPUs, such as the quest 2, reduce quality further
				quality = 0.2f;
			}
		}
	}
}
```

## Info Attributes
These are all the properties exposed on VRCPlatformCheck.
* `isMobile` - If running on a mobile
* `isAndroid` - If running on android
* `isIOS` - If running on ios 
* `isPc` - If running on pc
* `isReversedZ` - If the z depth is reversed. When this is false, it usually means it is running on a slower GPU such as on mobile
* `isAdreno600` - If running on a mobile adreno 600 series gpu with a depth bug such as the Quest 2 
* `isVr` - If running in vr
* `isStandaloneVr` - If running on a standalone vr headset
* `isQuest2` - If running on a quest 2
* `isProbablyQuest3` - If running on a quest 3. This is not precise and will also be true for most future android headsets


## Drawbacks
The Quest 1 is untested and may be detected as either a Quest 2 or a Quest 3. If the Quest 1's 500 series adreno gpu has the same bug as the Quest 2 it will be classified as the Quest 2. However the Quest 1 had a small user base and is discontinued, so you probably wont have many users who care about this.

The method of detecting the problem in the Quest 2's GPU could be patched in a future unity version, but it is somewhat unlikely.

The isProbablyQuest3 variable is a catch all for android standalone headsets that are not quest 2. This means that future headsets will be under this category. This is probably not an issue for most people unless you are doing something very specific to the quest 3.

You have to wait for the callback before acting on the values. If you do it before, it may not reflect the hardware.

## Contributions
If you know of a way to detect more information, open and issue detailing your method or create a pull request.

If you have a Quest 1 or a different untested mobile headset, consider testing this out so that the outcome is known. If you want to test without making a testing world. Go to [Realistic Tornado Quest](https://vrchat.com/home/world/wrld_226fd737-9af7-41ff-ab89-ff5b42f25c3a) and check the render target labeled `GPU Depth Test Render Target`. If the color is blue, it is detected as a Quest 3 and if it is pink it is detected as a Quest 2.