package
{
	import com.model.business.fileService.UrlSwfLoader;
	import com.model.business.fileService.constants.ResourcePathConstants;
	import com.model.business.fileService.interf.IUrlSwfLoaderReceiver;
	import com.model.business.flashVars.FlashVarsManager;
	import com.model.configData.ConfigDataGameLoader;
	import com.model.configData.ConfigDataNewMir;
	import com.model.configData.VersionList;
	import com.model.configData.VersionToDic;
	import com.view.gameLoader.IGameLoader;
	import com.view.gameLoader.StringConstGameLoader;
	import com.view.gameWindow.GameWindowResLoadProgressHandle;
	import com.view.gameWindow.util.HttpServiceUtil;
	import com.view.newMir.INewMir;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;

	public class GameLoader extends Sprite implements IUrlSwfLoaderReceiver,IGameLoader
	{
		private var _newMir:INewMir;
		private var _background:Bitmap;
		private var _loadings:Vector.<UILoading>;
		private var _loadIndex:int; 
		public function get loadIndex():int
		{
			return _loadIndex;
		}
		
		public function get isResLoaded():Boolean
		{
			return UILoading.isResLoaded;
		}
		
		public function GameLoader()
		{
			addEventListener(Event.ADDED_TO_STAGE, addToStageHandle);
		}

		private function addToStageHandle(event:Event):void
		{
			trace("addToStageHandle start..........................");
			removeEventListener(Event.ADDED_TO_STAGE, addToStageHandle);
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.quality = StageQuality.HIGH;
			stage.frameRate = 60;//帧频
			stage.stageFocusRect = false;//tab键不会出现黄色的框框
			init();
		}

		private function init():void
		{
			var flashVarsManager:FlashVarsManager = FlashVarsManager.getInstance();
			flashVarsManager.init(stage.loaderInfo.parameters)
			//初始化url链接
			ResourcePathConstants.initServerPath(FlashVarsManager.getInstance().resPath);
			ResourcePathConstants.initUrls();
			//初始化版本控制-
			var version:String;
			if(FlashVarsManager.getInstance().isResV){
//				version = ConfigDataGameLoader.version;
//				VersionToDic.versionToDic(version);
				VersionList.instance.add(ConfigDataGameLoader.getUIVersionList(),"ui",0);
			}
			//3
			stage.addEventListener(Event.RESIZE, resizeHandle, false, 0, true);
			initBackground();
			loadNewMir();
			 
			if (stage.stageWidth > 0 && stage.stageHeight > 0)
			{
				resizeHandle(null);
			}
			HttpServiceUtil.getInst().sendHttp(HttpServiceUtil.STEP1,1);
		}
		
		private function initBackground():void
		{
			_background = new Bitmap();
			_background.bitmapData = new BitmapData(100, 100, false, 0xff000000);
			addChild(_background);
		}
		
		private function loadNewMir():void
		{
			var loader:UrlSwfLoader = new UrlSwfLoader(this);
			var newMir:String = FlashVarsManager.getInstance().newMir;
			loader.loadSwf(newMir);
			_loadings = new Vector.<UILoading>();
			_loadIndex = showLoading(StringConstGameLoader.LOADING_TIP_0001);
			_loadings[_loadIndex].loadRes();
		}
		
		public function swfReceive(url:String, swf:Sprite,info:Object):void
		{
			_newMir = swf as INewMir;
			_newMir.setGameLoader(this);
			addChild(swf);
			resizeHandle(null);
		}
		
		public function swfProgress(url:String, progress:Number,info:Object):void 
		{
			setLoading(_loadIndex,progress);
		}
		
		public function swfError(url:String,info:Object):void
		{
			
		}
		
		private function resizeHandle(event:Event):void
		{
			var stageWidth:int = stage.stageWidth;
			var stageHeight:int = stage.stageHeight;
			if(_background.width==stageHeight&&_background.height==stageHeight)return;
			_background.width = stageWidth;
			_background.height = stageHeight;
			if (_newMir)
			{
				_newMir.resize(stageWidth, stageHeight);
			}
			var ui:UILoading;
			for each(ui in _loadings)
			{
				if(ui)
				{
					ui.resize();
				}
			}
		}
		
		public function setLoadingTip(index:int,text:String):void
		{
			var ui:UILoading = _loadings[index];
			if(ui)
			{
				ui.skin.txtTip.text = text;
			}
		}
		
		public function showLoading(text:String,visible:Boolean = true):int
		{
			var ui:UILoading = new UILoading(!visible, stage);
//			ui.stage = stage;
			ui.mcLoading.mcProgress.mcMask.scaleX = 0;
			ui.mcLoading.mcLoad.visible = false;
			ui.mcLoading.txt.text = text;
			ui.skin.visible = visible;
			ui.resize();
			//
			stage.addChild(ui.skin);
			//
			var i:int,l:int = _loadings.length;
			for(i=0;i<l;i++)
			{
				if(!_loadings[i])
				{
					_loadings[i] = ui;
					return i;
				}
			}
			_loadings.push(ui);
			return _loadings.length-1;
		}
		
		public function setLoadVisible(index:int,visible:Boolean):void
		{
			if(index < 0)
			{
				return;
			}
			var ui:UILoading = _loadings[index];
			if(ui)
			{
				ui.skin.visible = visible;
			}
		}
		
		public function setLoading(index:int,progress:Number):void
		{
			var ui:UILoading = _loadings[index];
			if(ui)
			{
				ui.checkChangeLoadingMode();
				ui.mcLoading.mcProgress.mcMask.scaleX = progress;
				ui.mcLoading.mcLoad.visible = progress>0&&progress<1;
				ui.mcLoading.mcLoad.x = ui.mcLoading.mcProgress.x+ui.mcLoading.mcProgress.width*progress+1;
				ui.mcLoading.txt.text = ui.mcLoading.txt.text.replace(/ \d*\.*\d*%/," "+(progress*100).toFixed(1)+"%");
			}
		}
		
		public function hideLoading(index:int):void
		{
			var ui:UILoading = _loadings[index];
			if(ui)
			{
				_loadings[index] = null;
				var loadIndex:int = GameWindowResLoadProgressHandle.instance.loadIndex;
				if(loadIndex == index)
				{
					ui.hideLoading();
				}
				var i:int,l:int = _loadings.length;
				for (i=0;i<l;i++) 
				{
					if(_loadings[i])
					{
						return;
					}
				}
				ui.hideLoading();
			}
		}
	}
}

import com.model.business.fileService.constants.ResourcePathConstants;
import com.model.business.flashVars.FlashVarsManager;
import com.model.consts.ConstGameCopy;
import com.model.gameWindow.rsr.RsrLoader;
import com.view.gameLoader.McLoading;
import com.view.gameLoader.McLoadingSmall;
import com.view.gameLoader.McLoadingSmallLY;
import com.view.gameLoader.McLoadingSmallRXHJ;
import com.view.gameLoader.StringConstGameLoader;
import com.view.gameWindow.util.Cover;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Stage;
import flash.events.Event;

class UILoading
{
	public var stage:Stage;
	private static var countLoaded:int;

	private static var _mcLoadingSmall:MovieClip;
	private static var _mcLoading:McLoading;
	private static var isResInited:Boolean = false;
	
	private var _isShowTrue:Boolean;
	
	private static var _mcLoadingSmallWidth:Number;
	private static var _mcLoadingSmallHeight:Number;
	private static var _mcLoadingWidth:Number;
	private static var _mcLoadingHeight:Number;
	
	public static function get isResLoaded():Boolean
	{
		return countLoaded >= 5;
	}
	
	public function UILoading(isShowTrue:Boolean = false,ctner:Stage = null)
	{
		if(ctner)
		{
			stage = ctner;
		}
		_isShowTrue = isShowTrue;
		if(!_mcLoadingSmall)
		{
			var versionTag:int = FlashVarsManager.getInstance().copy;
//			if(versionTag == ConstGameCopy.GAME_YOUXI_CQLL || versionTag == ConstGameCopy.GAME_360)
//			{
//				_mcLoadingSmall = new McLoadingSmallLY();
//			} 
//			else if(versionTag == ConstGameCopy.GAME_RXHJ)
//			{
//				_mcLoadingSmall = new McLoadingSmallRXHJ();
//			}
//			else
//			{
//				_mcLoadingSmall = new McLoadingSmallLY();
//			}
			_mcLoadingSmall = new McLoadingSmallLY();
			_mcLoadingSmallWidth = _mcLoadingSmall.width;
			_mcLoadingSmallHeight = _mcLoadingSmall.height;
			var cover:Cover = new Cover(0);
			_mcLoadingSmall.addChildAt(cover,0);
			
			_mcLoadingSmall.mouseChildren = false;
			_mcLoadingSmall.mouseEnabled = false;
		}
		
		if(!_mcLoading)
		{
			_mcLoading = new McLoading();
			_mcLoading.txtTip.text = StringConstGameLoader.CHAT_GAME_WARNING;
			_mcLoading.addEventListener(Event.ADDED_TO_STAGE,onAdded2Stage);
			_mcLoadingWidth = _mcLoading.width;
			_mcLoadingHeight = _mcLoading.height;
			_mcLoading.mouseChildren = false;
			_mcLoading.mouseEnabled = false;
		}
	
		loadRes();
	
		checkChangeLoadingMode();
	}
	
	protected function onAdded2Stage(event:Event):void
	{
		var cover:Cover = new Cover(0);
		_mcLoading.addChildAt(cover,0); 
	}
	
	public function loadRes():void
	{
		if(!isResInited)
		{
			var rsrLoader:RsrLoader = new RsrLoader(RsrLoader.TYPE_IMMEDIATE);
			var versionTag:int = FlashVarsManager.getInstance().copy;
			if (versionTag == ConstGameCopy.GAME_YOUXI_CQLL || versionTag == ConstGameCopy.GAME_360)
			{
				_mcLoading.mcBg.resUrl = "bg".concat(ResourcePathConstants.POSTFIX_JPG);
			} 
			else if (versionTag == ConstGameCopy.GAME_RXHJ)
			{
				_mcLoading.mcBg.resUrl = "bgRXHJ".concat(ResourcePathConstants.POSTFIX_JPG);
			}

			rsrLoader.addCallBack(_mcLoading.mcBg,callBack);
			rsrLoader.addCallBack(_mcLoading.mcProgressBg,callBack);
			rsrLoader.addCallBack(_mcLoading.mcProgress.mcProgressPic,callBack);
			rsrLoader.addCallBack(_mcLoading.mcLoad,callBack);
			rsrLoader.addCallBack(_mcLoading.mcProgress.progressMc,callBack);
			rsrLoader.load(_mcLoading,ResourcePathConstants.IMAGE_LOADING_FOLDER_LOAD);
			
			isResInited = true;
		}
	}
	
	private function callBack(mc:MovieClip):void
	{
		countLoaded++;
		checkChangeLoadingMode();
	}
	
	public function checkChangeLoadingMode():void
	{
		if(_isShowTrue && countLoaded >= 5)
		{
			if(_mcLoadingSmall.parent)
			{
				resize();
				_mcLoading.visible = _mcLoadingSmall.visible;
				_mcLoadingSmall.parent.addChild(_mcLoading);
				_mcLoadingSmall.parent.removeChild(_mcLoadingSmall);
			}
		}
	}
	
	public function resize():void
	{
		_mcLoading.x = (stage.stageWidth - _mcLoadingWidth)*.5;
		_mcLoading.y = (stage.stageHeight - _mcLoadingHeight)*.5;
		_mcLoadingSmall.x = (stage.stageWidth - _mcLoadingSmallWidth)*.5;
		_mcLoadingSmall.y = (stage.stageHeight - _mcLoadingSmallHeight)*.5;
	}
	
	public function get skin():MovieClip
	{
		if(countLoaded >= 4)
		{
			return _mcLoading;
		}
		return _mcLoadingSmall;
	}
	
	public function get mcLoading():McLoading
	{
		return _mcLoading;
	}
	
	public function hideLoading():void
	{
		if(_mcLoading.parent)
		{
			var numChildren:int = _mcLoading.numChildren;
			while(numChildren--)
			{
				var getChildAt:DisplayObject = _mcLoading.getChildAt(numChildren);
				if(getChildAt is Cover)
				{
					_mcLoading.removeChild(getChildAt);
				}
			}
			_mcLoading.parent.removeChild(_mcLoading);
		}
		if(_mcLoadingSmall.parent)
		{
			_mcLoadingSmall.parent.removeChild(_mcLoadingSmall);
		}
	}
}