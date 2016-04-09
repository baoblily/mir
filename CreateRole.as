package
{
	import com.model.business.fileService.constants.ResourcePathConstants;
	import com.model.configData.ConfigDataManager;
	import com.model.consts.JobConst;
	import com.model.consts.SexConst;
	import com.model.gameWindow.rsr.RsrLoader;
	import com.view.createRole.ICreateRole;
	import com.view.createRole.StringConstCreateRole;
	import com.view.gameWindow.GameWindowResLoadProgressHandle;
	import com.view.gameWindow.panel.panels.guardSystem.GuardManager;
	import com.view.gameWindow.panel.panels.prompt.McPanel1BtnPrompt;
	import com.view.gameWindow.util.LoaderCallBackAdapter;
	import com.view.gameWindow.util.TimerManager;
	import com.view.gameWindow.util.UIEffectLoader;
	import com.view.newMir.INewMir;
	import com.view.newMir.prompt.PanelPromptData;
	import com.view.newMir.prompt.SimplePromptPanel;
	import com.view.newMir.sound.SoundManager;
	import com.view.newMir.sound.constants.SoundIds;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.system.Security;
	import flash.ui.Keyboard;
	
	import mx.utils.StringUtil;

	public class CreateRole extends Sprite implements ICreateRole
	{
		private var _rsrLoader:RsrLoader;
		
		private var _newMir:INewMir;
		private var _skin:McCreateRoleNew;

		private var _lastClickBtn:MovieClip,_job:int,_sex:int;
		
		private var _width:int;
		private var _height:int;
		private var mcPanelBtnPrompt:McPanel1BtnPrompt;
		private var rect:Rectangle;
		private var _time:int = 25;
		private var isAuto:Boolean = false;
		private const TOTAL_CHARACTER_LENGTH:int = 14;//游戏名字不能超过7个汉字
//		private var enter:McEnterGame;
		private var selectOK:Boolean;
		private var imageOK:Boolean;
		private var tipOK:Boolean;
		private var effect:UIEffectLoader;
		private var _isWritten:Boolean;
		
		public function CreateRole()
		{
			GameWindowResLoadProgressHandle.instance.setVisible(false);
			addEventListener(Event.ADDED_TO_STAGE, addToStageHandle);
			Security.allowDomain("*");
		}

		private function addToStageHandle(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, addToStageHandle);
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.quality = StageQuality.HIGH;
			stage.stageFocusRect = false;//tab键不会出现黄色的框框
			
			initData();
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyBoardEvt, false, 0, true);
		}

        private function onKeyBoardEvt(event:KeyboardEvent):void
        {
            if (event.keyCode == Keyboard.ENTER)
            {
                enterGame();
            }
        }
		
		private function initData():void
		{
            this.mouseEnabled = false;
			_skin = new McCreateRoleNew();
			addChild(_skin);
			_rsrLoader = new RsrLoader();
			addCallBack(_rsrLoader);
			_rsrLoader.load(_skin,ResourcePathConstants.IMAGE_CREATEROLE_FOLDER_LOAD,false,null,loadComplete);
			_skin.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			_skin.mcBtns.txt.addEventListener(Event.CHANGE, onChangeTxt, false, 0, true);
			_skin.mcBtns.txt.addEventListener(FocusEvent.FOCUS_IN, onFocusIn, false, 0, true);
			_skin.mcBtns.txt.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut, false, 0, true);
//            _skin.contain.mouseEnabled = false;
//			enter = new McEnterGame;
//			_skin.addChild(enter);
//			enter.x = _skin.contain.x+315;
			effect = new UIEffectLoader(_skin.mcBtns,_skin.mcBtns.btnEnter.x ,_skin.mcBtns.btnEnter.y,1,1,"createRole/effect.swf",function():void
			{
				effect.effect.x = effect.effect.x+ _skin.mcBtns.btnEnter.width/2 + 2;
				effect.effect.y = effect.effect.y+_skin.mcBtns.btnEnter.height/2+1;
			});
			rollName();
			resetTime();
//			SoundManager.getInstance().playBgSound(SoundIds.SOUND_ID_LOGIN);
		}
		
		private function onFocusOut(e:FocusEvent):void
		{
			// TODO Auto Generated method stub
			if(e.target == _skin.mcBtns.txt)
			{
				resetTime();
			}
			
		}
		
		private function onFocusIn(e:FocusEvent):void
		{
			// TODO Auto Generated method stub
			if(e.target == _skin.mcBtns.txt)
			{
				TimerManager.getInstance().remove(updateTime);
			}
		}
		
		private var _loadCompleteCallback:Function;
		
		public function set loadCompleteHandler(func:Function):void
		{
			_loadCompleteCallback = func;
		}
		private function loadComplete():void
		{
			if(_loadCompleteCallback != null)
			{
				_loadCompleteCallback();
			}
		}

		private var _isChineseReg:RegExp = /[^u4E00-u9FA5]/;

		private function onChangeTxt(event:Event):void
		{
			var roleName:String = _skin.mcBtns.txt.text;
			var totalNum:int;
			var tempName:Array = [];
			var i:int = 0, len:int = 0;
			var name:String = "";
			for (i = 0, len = roleName.length; i < len; i++)
			{
				var char:String = roleName.charAt(i);
				var result:Boolean = _isChineseReg.test(char);
				result ? totalNum += 2 : totalNum++;
				tempName[totalNum] = char;
			}

			for (i = 0, len = tempName.length; i < len; i++)
			{
				if (i <= TOTAL_CHARACTER_LENGTH)
				{
					if (tempName[i])
					{
						name += tempName[i];
					}
				}
			}
			if (name.length > 0)
				_skin.mcBtns.txt.text = name;
			_isWritten = true;
		}
		
		private function addCallBack(rsrLoader:RsrLoader):void
		{
			_sex = SexConst.TYPE_MALE;
			_job = JobConst.TYPE_ZS;
			changeImage();
			
			rsrLoader.addCallBack(_skin.image,function(mc:MovieClip):void
			{
				imageOK = true;
				changeImage();
			});
			rsrLoader.addCallBack(_skin.tip,function(mc:MovieClip):void
			{
				tipOK = true;
				changeImage();
			});
			
			var loaderCallBackAdapter:LoaderCallBackAdapter = new LoaderCallBackAdapter();
			loaderCallBackAdapter.addCallBack(rsrLoader,function ():void
			{		
				selectOK = true;
				for(var i:int = 1;i<7;i++)
				{
					var sex:int = i%2==0?2:1;
					if(_job == (int((i-1)/2)+1)&& _sex == sex)
					{
						_lastClickBtn = _skin.mcSelect["btn"+i];
						_lastClickBtn.mouseEnabled = _lastClickBtn.mouseChildren = false;
						_lastClickBtn.selected = true;
					}else
					{
						_skin.mcSelect["btn"+i].selected = false;
					}
					_skin.mcSelect["btn"+i].visible = true;
				}
				changeImage();
			},_skin.mcSelect.btn1,_skin.mcSelect.btn2,_skin.mcSelect.btn3,_skin.mcSelect.btn4,_skin.mcSelect.btn5,_skin.mcSelect.btn6);
			
			
		}
		
		protected function onClick(event:MouseEvent):void
		{
			switch(event.target)
			{
				case _skin.mcBtns.btnRoll:
					resetTime();
					rollName();
					break;
				case _skin.mcBtns.btnEnter:
                    enterGame();
					break;
//				case _skin.contain.btnReturn:
//					_newMir.dealSelectRole();
//					break;
				case _skin.mcSelect.btn1:
					resetTime();
					selectJob(_skin.mcSelect.btn1,JobConst.TYPE_ZS,SexConst.TYPE_MALE);
					changeImage();
					break;
				case _skin.mcSelect.btn2:
					resetTime();
					selectJob(_skin.mcSelect.btn2,JobConst.TYPE_ZS,SexConst.TYPE_FEMALE);
					changeImage();
					break;
				case _skin.mcSelect.btn3:
					resetTime();
					selectJob(_skin.mcSelect.btn3,JobConst.TYPE_FS,SexConst.TYPE_MALE);
					changeImage();
					break;
				case _skin.mcSelect.btn4:
					resetTime();
					selectJob(_skin.mcSelect.btn4,JobConst.TYPE_FS,SexConst.TYPE_FEMALE);
					changeImage();
					break;
				case _skin.mcSelect.btn5:
					resetTime();
					selectJob(_skin.mcSelect.btn5,JobConst.TYPE_DS,SexConst.TYPE_MALE);
					changeImage();
					break;
				case _skin.mcSelect.btn6:
					resetTime();
					selectJob(_skin.mcSelect.btn6,JobConst.TYPE_DS,SexConst.TYPE_FEMALE);
					changeImage();
					break;
				default :
					break;
			}
		}
		
		
		private function changeImage():void
		{
			// TODO Auto Generated method stub
			if(!selectOK||!imageOK||!tipOK)
			{
				_skin.image.visible = false;
				_skin.tip.visible = false;
				return;
			}
			_skin.tip.visible = true;
			_skin.image.visible = true;
			if(_job == JobConst.TYPE_ZS)
			{
				if(_sex ==SexConst.TYPE_MALE)
					_skin.image.gotoAndStop(1);
				else
					_skin.image.gotoAndStop(2);
			}
			else if(_job == JobConst.TYPE_FS)
			{
				if(_sex ==SexConst.TYPE_MALE)
					_skin.image.gotoAndStop(3);
				else
					_skin.image.gotoAndStop(4);
			}
			else if(_job == JobConst.TYPE_DS)
			{
				if(_sex ==SexConst.TYPE_MALE)
					_skin.image.gotoAndStop(5);
				else
					_skin.image.gotoAndStop(6);
			}
			_skin.tip.gotoAndStop(_job);
		}
		
		private function resetTime():void
		{
//			var obj:Object =  TimeUtils.calcTime3(_time);
			TimerManager.getInstance().remove(updateTime);
			_time = 25;
			_skin.mcBtns.timeText.text = 25 + StringConstCreateRole.PROMPT_PANEL_0045;
			TimerManager.getInstance().add(1000,updateTime);
		}
		
		public function updateTime():void 
		{
			_time -= 1;
//			_rewardTime = getOnlineRewardCfg().seconds - _online;
//			var num:int = int(_rewardTime/60);
			if(_skin)
			{
				if(0 >= _time)
				{
					TimerManager.getInstance().remove(updateTime); 
					
					if(StringUtil.trim(_skin.mcBtns.txt.text) == "")
					{
						rollName();
					}
					enterGame();
					isAuto= true;
					_skin.mcBtns.timeText.text = _time + StringConstCreateRole.PROMPT_PANEL_0045;
					_time = 25;
					return;
				}
				_skin.mcBtns.timeText.text = _time + StringConstCreateRole.PROMPT_PANEL_0045;
			}
		}
		
        private function enterGame():void
        {
            if (_skin)
            {
				var name:String = "";
				
				if(_skin.mcBtns && _skin.mcBtns.txt)
				{
					name = _skin.mcBtns.txt.text;
					name = StringUtil.trim(name);
					if(name)
					{
						name = name.replace(invalidWord,"");
					}
					_skin.mcBtns.txt.text = name;
				}
				
				if(name)
				{
	                if (GuardManager.getInstance().containBannedWord(name) == true)
	                {
	                    PanelPromptData.txtName = StringConstCreateRole.PROMPT_PANEL_0001;
	                    PanelPromptData.txtContent = StringConstCreateRole.PROMPT_PANEL_0002;
	                    PanelPromptData.txtBtn = StringConstCreateRole.PROMPT_PANEL_0003;
	                    var prompt:SimplePromptPanel = new SimplePromptPanel();
	                    prompt.init(stage);
	                    return;
	                }
					
	                _newMir.newCharacter(name, _sex, _job);
				}
            }
        }
		
		private function selectJob(clickBtn:MovieClip,job:int,sex:int):void
		{
//			_selectedJob.image.gotoAndStop(_sex);
			_job = job;
			if(_sex!=sex)
			{
				_sex = sex;
				resetTime();
				rollName();
			}
//			_sex = sex;
			_lastClickBtn.selected = false;
			_lastClickBtn.mouseEnabled = _lastClickBtn.mouseChildren = true;
			_lastClickBtn = clickBtn;
			_lastClickBtn.mouseEnabled = _lastClickBtn.mouseChildren = false;
			_lastClickBtn.selected = true;
		}
		
		
//		private var _maleName:Array;
//		private var _femaleName:Array;
//		private var _lastName:Array;
//		private var _wholeName:Array;
//		
//		private function initRoleNames():void
//		{
//			if(!_maleName)
//			{
//				_maleName = ConfigDataManager.instance.maleNameConfig.concat();
//				_femaleName = ConfigDataManager.instance.femaleNameConfig.concat();
//				_wholeName = ConfigDataManager.instance.wholeNameConfig.concat();
//				_lastName = ConfigDataManager.instance.lastNameConfig.concat();
//			}
//		}
		
		private function getRandomName(sex:int):String
		{
			var name:Array = sex == SexConst.TYPE_MALE ? ConfigDataManager.instance.maleNameConfig : ConfigDataManager.instance.femaleNameConfig;
			var whole:Array = ConfigDataManager.instance.wholeNameConfig;
			var lastName:Array = ConfigDataManager.instance.lastNameConfig;
			
//			var name:Array = sex == SexConst.TYPE_MALE ? _maleName : _femaleName;
//			var whole:Array = _wholeName;
//			var lastName:Array = _lastName;
			
			var randomName:String = "";
			var time:Number = (new Date()).time;
			while (true)
			{
				var random:Number = Math.random()*time;
				var randomValue:int = random%10000;
				
				if (randomValue > 500)
				{
					var lastNameIndex:int = random % lastName.length;
					var nameIndex:int = random % name.length;
					randomName = lastName[lastNameIndex] + name[nameIndex];
				}
				else
				{
					var wholeIndex:int = random % whole.length;
					randomName = whole[wholeIndex];
				}
				
				randomName = randomName.replace(invalidWord,"");
				if (randomName && !GuardManager.getInstance().containBannedWord(randomName))
				{
					break;
				}
			}
			
			return randomName;
		}
		
		private function rollName():void
		{
			if(_skin)
			{
				_skin.mcBtns.txt.text = "";
				_skin.mcBtns.txt.text = getRandomName(_sex);
			}
			_isWritten = false;
		}
		
		private var invalidWord:RegExp = /[:|,|{|}|\n|\r]/g;
		
		public function resize(newWidth:int, newHeight:int):void
		{
			_width = newWidth;
			_height = newHeight;
			_skin.x = (_width - _skin.width)/2;
			_skin.y = (_height - _skin.height)/2;
//			_skin.layer.y = -_skin.y;
//			_skin.contain.y = _height - 317-_skin.y;
//			enter.y = _skin.contain.y+177;
			if(mcPanelBtnPrompt)
			{
				mcPanelBtnPrompt.x = int((_width - rect.width)*.5);
				mcPanelBtnPrompt.y = int((_height - rect.height)*.5);
			}
			if(_width<_skin.width)
			{
				var _x:int = _skin.width + _skin.x;
				var _y:int = _height - _skin.y;
				_skin.mcSelect.x = _x - _skin.mcSelect.width;
				if(_skin.mcSelect.x>_skin.image.x+_skin.image.width+226)
				{
					_skin.mcSelect.x=_skin.image.x+_skin.image.width+226;
				}
				_skin.mcBtns.y = _y - _skin.mcBtns.height;
				if(_skin.mcBtns.y>_skin.image.y+_skin.image.height-35)
				{
					_skin.mcBtns.y = _skin.image.y+_skin.image.height-35;
				}
				if(_skin.tip.x<_skin.image.x-178)
					_skin.tip.x = _skin.image.x - 178;
			}else
			{
				_x = _skin.width;
				_y = _skin.height;
				_skin.mcSelect.x = _x - 500;
				_skin.mcBtns.y = _y - 230;
				_skin.tip.x = 300;
			}
		}
		
		public function refreshData():void
		{
//			var vector:Vector.<MovieClip> = Vector.<MovieClip>([_skin.contain.btnZhan,_skin.contain.btnFa,_skin.contain.btnDao]);
			_sex = Math.ceil(Math.random()*2);
			_job = Math.ceil(Math.random()*3);
//			_skin.contain.btnReturn.visible = SelectRoleDataManager.getInstance().selectRoleDatas != null;
		}
		
		public function set newMir(value:INewMir):void
		{
			_newMir = value;
			SoundManager.getInstance().newMir = value;
		}
		
		public function dealName():void
		{
			if(isAuto)
			{
				rollName();
				enterGame();
			}
			else
			{
//				PanelPromptData.txtName = StringConstCreateRole.PROMPT_PANEL_0001;
//				PanelPromptData.txtContent = StringConstCreateRole.PROMPT_PANEL_0004;
//				PanelPromptData.txtBtn = StringConstCreateRole.PROMPT_PANEL_0003;
//				_newMir.showNameExist();
//				rollName();
			}
		}
		
		public function dealNameExists():void
		{
			_newMir.showNameExist();
			
			if(isAuto)
			{
				resetTime();
			}
			
			rollName();
		}
		
		public function destroy():void
		{
			rect = null;
			mcPanelBtnPrompt = null;
			_lastClickBtn = null;
			if(effect)
			{
				effect.destroy();
				effect = null;
			}
			
			if(_skin)
			{
				_skin.removeEventListener(MouseEvent.CLICK,onClick);
				_skin.mcBtns.txt.removeEventListener(Event.CHANGE, onChangeTxt);
//                if (_skin.roleBtn_00)
//                    _skin.roleBtn_00.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
//                if (_skin.roleBtn_01)
//                    _skin.roleBtn_01.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			}
            if (stage)
            {
                stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyBoardEvt);
            }
			_skin = null;
			_newMir = null;
			if(parent)
			{
				parent.removeChild(this);
			}
			if(_rsrLoader)
			{
				_rsrLoader.destroy();
				_rsrLoader = null;
			}
		}
	}
}