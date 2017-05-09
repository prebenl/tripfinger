import React from 'react';
import ReactNative from 'react-native';
import { SegmentedControls } from 'react-native-radio-buttons';
import NavBar from '../../NavBar';
import Globals from '../../shared/Globals';
import Utils from '../../shared/Utils';
import ListingsList from './ListingsList';
import ListingsSwiper from './ListingsSwiper';

const View = ReactNative.View;
const StyleSheet = ReactNative.StyleSheet;

export default class CategoryScene extends React.Component {

  // noinspection JSUnusedGlobalSymbols
  static propTypes = {
    navigator: React.PropTypes.object,
    sceneProps: React.PropTypes.object,
    categoryDesc: React.PropTypes.object.isRequired,
    region: Globals.propTypes.guideItem.isRequired,
  };

  // noinspection JSUnusedGlobalSymbols
  static title = (props) => {
    if (props.categoryDesc.subCategory) {
      return Utils.categoryName(props.categoryDesc.subCategory);
    } else {
      return Utils.categoryName(props.categoryDesc.category);
    }
  };

  constructor(props) {
    super(props);
    const isAttractions = this.props.categoryDesc.category === Globals.categories.attractions;
    this.state = {
      selectedOption: isAttractions ? 'Swipe' : 'List',
    };
  }

  _renderContent = () => {
    if (this.state.selectedOption === 'List') {
      return (
        <ListingsList
          categoryDesc={this.props.categoryDesc} region={this.props.region}
          navigator={this.props.navigator}
        />
      );
    } else {
      return (
        <ListingsSwiper
          navigator={this.props.navigator} region={this.props.region}
          categoryDesc={this.props.categoryDesc}
        />
      );
    }
  };

  _renderHeader() {
    if (this.props.categoryDesc.category !== Globals.categories.attractions) {
      return null;
    }
    return (
      <View style={styles.segmented}>
        <SegmentedControls
          options={['Swipe', 'List']}
          selectedOption={this.state.selectedOption}
          onSelection={opt => this.setState({ selectedOption: opt })}
          tint={'#555'}
          selectedTint={'#fff'}
          backTint={'#fff'}
          paddingTop={8}
          paddingBottom={8}
        />
      </View>
    );
  }

  render() {
    return (
      <View style={styles.container}>
        <NavBar navigator={this.props.navigator} sceneProps={this.props.sceneProps} />
        {this._renderHeader()}
        <View style={styles.subContainer}>
          {this._renderContent()}
        </View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    flex: 1,
  },
  segmented: {
    marginTop: 64,
    width: 200,
    paddingTop: 20,
    paddingBottom: 20,
  },
  subContainer: {
    flex: 1,
    alignSelf: 'stretch',
  },
});
