# Created by Satoshi Nakagawa.
# You can redistribute it and/or modify it under the Ruby's license or the GPL2.

require 'dialoghelper'

class WelcomeDialog
  include DialogHelper
  attr_accessor :delegate, :prefix
  attr_writer :window, :nickText, :serverCombo, :channelTable, :autoConnectCheck
  attr_writer :okButton, :addChannelButton, :deleteChannelButton
  
  def initialize
    @prefix = 'welcomeDialog'
    @channels = []
  end
  
  def start
    NSBundle.loadNibNamed('WelcomeDialog', owner:self)
    tableViewSelectionIsChanging(nil)
    @channelTable.text_delegate = self
    ServerDialog.servers.each {|i| @serverCombo.addItemWithObjectValue(i) }
    load
    update_ok_button
    show
  end
  
  def show
    unless @window.isVisible
      @window.centerOfScreen
    end
    @window.makeKeyAndOrderFront(self)
  end
  
  def close
    @delegate = nil
    @window.close
  end
  
  def windowWillClose(sender)
    fire_event('onClose')
  end
  
  def onOk(sender)
    @channels.uniq!
    @channels.delete('')
    @channels.map! do |i|
      i.channelname? ? i : '#' + i
    end
    c = {
      :nick => @nickText.stringValue.to_s,
      :host => @serverCombo.stringValue.to_s,
      :channels => @channels,
      :auto_connect => @autoConnectCheck.state.to_i != 0,
    }
    fire_event('onOk', c)
    @window.close
  end
  
  def onCancel(sender)
    @window.close
  end
  
  def onAddChannel(sender)
    @channels << ''
    @channelTable.reloadData
    row = @channels.size - 1
    @channelTable.select(row)
    @channelTable.editColumn(0, row:row, withEvent:nil, select:true)
  end

  def onDeleteChannel(sender)
    n = @channelTable.selectedRows[0]
    if n
      @channels.delete_at(n)
      @channelTable.reloadData
    end
  end
  
  def numberOfRowsInTableView(sender)
    @channels.size
  end
  
  def tableView(sender, objectValueForTableColumn:col, row:row)
    @channels[row]
  end
  
  def tableViewSelectionIsChanging(note)
    @deleteChannelButton.setEnabled(!@channelTable.selectedRows.empty?)
  end
  
  def textDidEndEditing(note)
    n = @channelTable.editedRow
    if n >= 0
      @channels[n] = note.object.textStorage.string.to_s
      @channelTable.reloadData
      @channelTable.select(n)
    end
  end
  
  def controlTextDidChange(note)
    update_ok_button
  end
  
  def onServerComboChanged(sender)
    update_ok_button
  end
  
  private
  
  def load
    nick = NSUserName().gsub(/\s/, '')
    if /\A[a-z][-_a-z\d]*\z/i =~ nick
      @nickText.setStringValue(nick)
    end
  end
  
  def update_ok_button
    nick = @nickText.stringValue.to_s
    server = @serverCombo.stringValue.to_s
    @okButton.setEnabled(!nick.empty? && !server.empty?)
  end
end
