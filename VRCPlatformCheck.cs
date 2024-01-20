
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class VRCPlatformCheck : UdonSharpBehaviour
{
	[Header("If running on a mobile")]
	public bool isMobile = false;
	
	[Header("If running on android")]
	public bool isAndroid = false;
	
	[Header("If running on ios")]
	public bool isIOS = false;
	
	[Header("If running on pc")]
	public bool isPc = false;
	
	[Header("If the z depth is reversed\n"+
	"When this is false, it usually means it is running on a slower GPU such as on mobile")]
	public bool isReversedZ = false;
	
	[Header("If running on a mobile adreno 600 series gpu with a depth bug such as the quest 2")]
	public bool isAdreno600 = false;
	
	[Header("If running in vr")]
	public bool isVr = false;
	
	[Header("If running on a standalone vr headset")]
	public bool isStandaloneVr = false;
	
	[Header("If running on a quest 2")]
	public bool isQuest2 = false;
	
	[Header("If running on a quest 3\n" +
	"This is not precise and will also be true for most future android headsets"
	)]
	public bool isProbablyQuest3 = false;
	
	
	public UdonSharpBehaviour[] callbackScripts;
	
	// mainly for testing
	public Color outputColor;
	[SerializeField] // scratch texture
	private Texture2D scratchTexture;
	[SerializeField] // wait a few frames
	private int successCount = 0;
	void Start()
	{
		#if UNITY_ANDROID
		isAndroid = true;
		#else
		isAndroid = false;
		#endif
		
		#if UNITY_IOS
		isIOS = true;
		#else
		isIOS = false;
		#endif
		
		isMobile = isAndroid || isIOS;
		isPc = !isMobile;
		
		if(Networking.LocalPlayer != null){
			isVr = Networking.LocalPlayer.IsUserInVR();
		}
		
		isStandaloneVr = isMobile && isVr;
		
		successCount = 0;
	}
	void OnPostRender(){
		scratchTexture.ReadPixels(new Rect(0, 0, 32, 32), 0, 0);
		Color[] allData = scratchTexture.GetPixels();
		outputColor = allData[scratchTexture.width * (scratchTexture.height / 2) + scratchTexture.width / 2];
		if(outputColor.r >= 1.0f || outputColor.g >= 1.0f || outputColor.b >= 1.0f){
			successCount++;
			if(successCount >= 10){
				GetComponent<Camera>().enabled = false;
				if(outputColor.g >= 1.0f){
					// reversed z, probably pc
					isReversedZ = true;
					isAdreno600 = false;
				}else if(outputColor.b >= 1.0f){
					// unreversed z, probably mobile
					isReversedZ = false;
					// check for z depth bug on adreno gpus
					isAdreno600 = outputColor.r >= 1.0f;
				}
				isQuest2 = isVr && isAndroid && isAdreno600;
				isProbablyQuest3 = isVr && isAndroid && !isAdreno600;
				foreach(UdonSharpBehaviour callbackScript in callbackScripts){
					callbackScript.SendCustomEvent("OnPlatformCheck");
				}
				SendCustomEvent("OnPlatformCheck");
			}
		}
	}
}
