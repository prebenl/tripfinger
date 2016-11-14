import React from 'react';
import ReactNative from 'react-native';

const StyleSheet = ReactNative.StyleSheet;
const Text = ReactNative.Text;
const TouchableHighlight = ReactNative.TouchableHighlight;
const View = ReactNative.View;

export default class StandardCell extends React.Component {

  // noinspection JSUnusedGlobalSymbols
  static propTypes = {
    text: React.PropTypes.string.isRequired,
    onPress: React.PropTypes.func,
    isFirstRow: React.PropTypes.bool,
    isLastRow: React.PropTypes.bool,
    firstRowInSectionStyle: React.PropTypes.any,
  };

  render() {
    const rowStyles = [styles.row];
    if (this.props.isFirstRow) {
      if (this.props.firstRowInSectionStyle) {
        rowStyles.push(this.props.firstRowInSectionStyle);
      } else {
        rowStyles.push(styles.firstRowInSection);
      }
    }
    if (this.props.isLastRow) {
      rowStyles.push(styles.lastRowInSection);
    }
    return (
      <TouchableHighlight
        style={rowStyles}
        underlayColor="#DDDDDD"
        onPress={this.props.onPress}
      >
        <View style={styles.innerRow}>
          <Text style={styles.rowText}>{this.props.text}</Text>
        </View>
      </TouchableHighlight>
    );
  }
}

const styles = StyleSheet.create({
  row: {
    paddingLeft: 23,
    height: 50,
    backgroundColor: '#FFFFFF',
  },
  firstRowInSection: {
    marginTop: 20,
  },
  lastRowInSection: {
    borderBottomWidth: 0.5,
    borderBottomColor: '#ccc',
  },
  innerRow: {
    height: 50,
    justifyContent: 'center',
    borderBottomWidth: 0.5,
    borderBottomColor: '#ccc',
  },
  rowHighlight: {
    flex: 1,
  },
  rowText: {
    fontSize: 16,
  },
});
