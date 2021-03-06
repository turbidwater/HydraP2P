/*
 * Copyright 2010 (c) Dominic Graefen, devboy.org.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
package org.devboy.hydra
{
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.GroupSpecifier;
	import flash.net.NetGroup;
	
	import org.devboy.hydra.packets.HydraPacketEvent;
	import org.devboy.hydra.packets.IHydraPacket;
	import org.devboy.hydra.users.HydraUserEvent;
	import org.devboy.hydra.users.HydraUserTracker;
	import org.devboy.toolkit.net.NetGroupNeighbor;
	import org.devboy.toolkit.net.NetGroupNeighborEvent;
	import org.devboy.toolkit.net.NetStatusCodes;

	/**
	 *  Dispatched when the <code>HydraChannel</code> connects 
	 *  successfully to the service string. 
	 * 
	 *  This event is dispatched only when the 
	 *  hydra service trys to connect to the service url.
	 *
	 *  @eventType org.devboy.hydra.HydraEvent.CHANNEL_CONNECT_SUCCESS
	 */
	[Event(name="channelConnectSuccess", type="org.devboy.hydra.HydraEvent")]
	
	/**
	 *  Dispatched when the <code>HydraChannel</code> connection 
	 *  has failed. 
	 * 
	 *  This event is dispatched only when the 
	 *  hydra service trys to connect to the service url.
	 *
	 *  @eventType org.devboy.hydra.HydraEvent.CHANNEL_CONNECT_FAILED
	 */
	[Event(name="channelConnectFailed", type="org.devboy.hydra.HydraEvent")]
	
	/**
	 *  Dispatched when the <code>HydraChannel</code> connection 
	 *  is rejected. 
	 *
	 *  @eventType org.devboy.hydra.HydraEvent.CHANNEL_CONNECT_REJECTED
	 */
	[Event(name="channelConnectRejected", type="org.devboy.hydra.HydraEvent")]
	
	/**
	 *  Dispatched when the <code>HydraChannel</code> sends a message. 
	 *
	 *  @eventType org.devboy.hydra.packets.HydraPacketEvent.PACKET_SENT
	 */
	[Event(name="packetSent", type="org.devboy.hydra.packets.HydraPacketEvent")]
	
	/**
	 *  Dispatched when the <code>HydraChannel</code> sends a message. 
	 *
	 *  @eventType org.devboy.hydra.packets.HydraPacketEvent.PACKET_RECEIVED
	 */
	[Event(name="packetReceived", type="org.devboy.hydra.packets.HydraPacketEvent")]
	
	/**
	 *  Dispatched when the <code>HydraChannel</code> sends a message. 
	 *
	 *  @eventType org.devboy.hydra.packets.HydraPacketEvent.PACKET_RECEIVED
	 */
	[Event(name="packetReceived", type="org.devboy.hydra.packets.HydraPacketEvent")]
	
	/**
	 *  Dispatched when a user joins the <code>HydraChannel</code>. 
	 *
	 *  @eventType org.devboy.hydra.users.HydraUserEvent.USER_CONNECT
	 */
	[Event(name="userConnect", type="org.devboy.hydra.users.HydraUserEvent")]
	
	/**
	 *  Dispatched when a user leaves the <code>HydraChannel</code>. 
	 *
	 *  @eventType org.devboy.hydra.users.HydraUserEvent.USER_DISCONNECT
	 */
	[Event(name="userDisconnect", type="org.devboy.hydra.users.HydraUserEvent")]
	
	/**
	 * @author Dominic Graefen - devboy.org
	 */
	public class HydraChannel extends EventDispatcher
	{
		private var _channelId : String;
		private var _netGroup : NetGroup;
		private var _hydraService : HydraService;
		private var _connected : Boolean;
		private var _userTracker : HydraUserTracker;
		private var _specifier : GroupSpecifier;
		private var _withAuthorization : Boolean;
		private var _autoConnect : Boolean;

		public function HydraChannel(hydraService : HydraService, channelId : String, specifier : GroupSpecifier, withAuthorization : Boolean, autoConnect : Boolean = true )
		{
			_autoConnect = autoConnect;
			_withAuthorization = withAuthorization;
			_specifier = specifier;
			
			if(hydraService.usingServerlessRtmfp)
			{
				_specifier.addIPMulticastAddress(hydraService.ipMulticastAddress);
				_specifier.ipMulticastMemberUpdatesEnabled = true;
				_specifier.serverChannelEnabled = false;
			}
			else
			{
				// since we're not using serverless let's bootstrap
				_specifier.serverChannelEnabled = true;
			}
			
			// let's always enable posting and routing
			_specifier.postingEnabled = true;
			_specifier.routingEnabled = true;
			
			_hydraService = hydraService;
			_channelId = channelId;
			super(this);
			init();
		}

		private function init() : void
		{
			initUserTracker()
			_hydraService.addChannel(this);
		}
		
		protected function initUserTracker():void
		{
			_userTracker = new HydraUserTracker(this);
			_userTracker.addEventListener(HydraUserEvent.USER_CONNECT, dispatchEvent);
			_userTracker.addEventListener(HydraUserEvent.USER_DISCONNECT, dispatchEvent);
		}

		public function connect() : void
		{
			if(!_hydraService.connected)
				throw new Error( "HydraService needs to be connected first");
				
			_hydraService.netConnection.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
			_netGroup = new NetGroup(_hydraService.netConnection, _withAuthorization ? _specifier.groupspecWithAuthorizations() : _specifier.groupspecWithoutAuthorizations());
			_netGroup.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
		}
		
		public function addNeighbor(peerID : String) : Boolean
        {
            return netGroup.addNeighbor(peerID);
        }

        public function addMemberHint(peerID : String) : Boolean
        {
            return netGroup.addMemberHint(peerID);
        }

		protected function netStatus(event : NetStatusEvent) : void
		{
			var infoCode : String = event.info.code;
			dispatchEvent( event ); //REMOVE
			switch (infoCode)
			{
				case NetStatusCodes.NETGROUP_CONNECT_SUCCESS:
				case NetStatusCodes.NETGROUP_CONNECT_REJECTED:
				case NetStatusCodes.NETGROUP_CONNECT_FAILED:
					if (event.info.group && event.info.group == _netGroup)
					{
						_connected = infoCode == NetStatusCodes.NETGROUP_CONNECT_SUCCESS;
						_userTracker.addUser(_hydraService.user);
						dispatchEvent(new HydraEvent(getEventTypeForNetGroup(infoCode))); //REMOVE
						_hydraService.netConnection.removeEventListener(NetStatusEvent.NET_STATUS, netStatus);
					}
					break;
				case NetStatusCodes.NETGROUP_NEIGHBOUR_CONNECT:
					dispatchEvent(new NetGroupNeighborEvent(NetGroupNeighborEvent.NEIGHBOR_CONNECT, new NetGroupNeighbor(event.info.neighbor as String, event.info.peerID as String)));
					break;
				case NetStatusCodes.NETGROUP_NEIGHBOUR_DISCONNECT:
					dispatchEvent(new NetGroupNeighborEvent(NetGroupNeighborEvent.NEIGHBOR_DISCONNECT, new NetGroupNeighbor(event.info.neighbor as String, event.info.peerID as String)));
					break;
				case NetStatusCodes.NETGROUP_POSTING_NOTIFY:
					receivePacket(event.info.message);
                    break;
				case NetStatusCodes.NETGROUP_ROUTING_SENDTO_NOTIFY:
					receivePacket(event.info.message);
					break;				
			}
		}
		
		protected function receivePacket( message : Object ) : void
		{
			var userId : String = message.userId;
			var type : String = message.type;
			var timestamp : Number = message.timestamp;
			var info : Object = message.info;
			var senderPeerId : String = message.senderPeerId;
			var packet : IHydraPacket = _hydraService.packetFactory.createPacket(type, timestamp, userId, senderPeerId, info);
			if( packet )
				dispatchEvent( new HydraPacketEvent(HydraPacketEvent.PACKET_RECEIVED, packet));		
		}
		
		public function sendPacket( packet : IHydraPacket ) : void
		{
			packet.userId = _hydraService.user.uniqueId;
			packet.timestamp = new Date().getTime();
			var message : Object = new Object();
			message.userId = packet.userId;
			message.type = packet.type;
			message.timestamp = packet.timestamp;
			message.info = packet.info;
			message.senderPeerId = _hydraService.netConnection.nearID;
			
			// We check to see if netgroup neighbors are 13 or less. If so and we've decided to use routing, 
			// then we route. Faster than post in a fully meshed group.
			// See: http://tv.adobe.com/watch/max-2011-develop/advanced-p2p-with-rtmfp-tips-and-tricks/
			if( _hydraService.useRoutingWhenFullyMeshed 
				&& ( _netGroup.neighborCount < 13 && _netGroup.estimatedMemberCount < 14 ) )
			{	
				_netGroup.sendToAllNeighbors(message);
			}
			else
			{
			
				_netGroup.post(message);
			}	
			dispatchEvent( new HydraPacketEvent(HydraPacketEvent.PACKET_SENT, packet));
		}

		private function getEventTypeForNetGroup(infoCode : String) : String
		{
			var eventType : String;
			switch(infoCode)
			{
				case NetStatusCodes.NETGROUP_CONNECT_SUCCESS:
					eventType = HydraEvent.CHANNEL_CONNECT_SUCCESS;
					break;
				case NetStatusCodes.NETGROUP_CONNECT_FAILED:
					eventType = HydraEvent.CHANNEL_CONNECT_FAILED;
					break;
				case NetStatusCodes.NETGROUP_CONNECT_REJECTED:
					eventType = HydraEvent.CHANNEL_CONNECT_REJECTED;
					break;
			}
			return eventType;
		}

		public function get connected() : Boolean
		{
			return _connected;
		}

		public function get channelId() : String
		{
			return _channelId;
		}

		public function get hydraService() : HydraService
		{
			return _hydraService;
		}

		public function get autoConnect() : Boolean
		{
			return _autoConnect;
		}

		public function get userTracker() : HydraUserTracker
		{
			return _userTracker;
		}

		protected function get netGroup() : NetGroup
		{
			return _netGroup;
		}
	}
}
