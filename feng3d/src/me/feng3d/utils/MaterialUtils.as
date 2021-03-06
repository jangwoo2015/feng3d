package me.feng3d.utils
{
	import flash.display.Bitmap;
	
	import me.feng.core.GlobalDispatcher;
	import me.feng.load.Load;
	import me.feng.load.LoadEvent;
	import me.feng3d.materials.TextureMaterial;

	/**
	 * 纹理材质工厂
	 * @author warden_feng 2014-7-7
	 */
	public class MaterialUtils
	{
		private static var dispatcher:GlobalDispatcher = GlobalDispatcher.instance;

		public static function createTextureMaterial(url:String):TextureMaterial
		{
			Load.init();
			
			var textureMaterial:TextureMaterial = new TextureMaterial();

			var loadObj:Object = {};
			loadObj.urls = [url];
			loadObj.singleComplete = singleGeometryComplete;
			loadObj.singleCompleteParam = {textureMaterial: textureMaterial}
			dispatcher.dispatchEvent(new LoadEvent(LoadEvent.LOAD_RESOURCE, loadObj));

			return textureMaterial;
		}

		/** 单个图片加载完毕 */
		private static function singleGeometryComplete(param:Object):void
		{
			var textureMaterial:TextureMaterial = param.textureMaterial;
			var bitmap:Bitmap = param.loadingItem.loader.content;
			textureMaterial.texture = Cast.bitmapTexture(bitmap);
		}
	}
}
